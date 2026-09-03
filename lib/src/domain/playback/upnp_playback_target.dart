import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/diagnostics/diagnostics.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/didl_lite.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:upnp_quirks/upnp_quirks.dart';

class UpnpPlaybackTarget implements PlaybackTarget {
  UpnpPlaybackTarget(
    this.renderer, {
    Duration? pollInterval,
    this.diagnostics = const Diagnostics(),
  }) : pollInterval = pollInterval ?? renderer.quirks.pollInterval;

  static const _restartThreshold = Duration(seconds: 3);
  static const _failureLimit = 3;

  final UpnpRenderer renderer;
  final Duration pollInterval;
  final Diagnostics diagnostics;

  final _controller = StreamController<TargetPlaybackState>.broadcast();
  final _tracks = <TargetTrack>[];

  Future<void> _commands = Future<void>.value();
  Timer? _poll;
  var _index = 0;
  TargetPlaybackState _state = TargetPlaybackState.idle;
  var _sawPlaying = false;
  var _stopRequested = false;
  var _failures = 0;
  var _idlePolls = 0;
  var _pollGeneration = 0;
  var _disposed = false;
  var _nextUriUsable = true;
  Uri? _nextUriSet;

  AvTransport get _transport => renderer.avTransport;

  DeviceQuirks get _quirks => renderer.quirks;

  bool get _canQueueNextTrack =>
      _quirks.queueNextTrack && _transport.supportsNextUri && _nextUriUsable;

  @override
  String get id => renderer.id;

  @override
  String get name => renderer.name;

  @override
  PlaybackTargetKind get kind => PlaybackTargetKind.upnp;

  @override
  StreamTargetProfile get streamProfile =>
      StreamTargetProfile.renderer(sinkMimeTypes: renderer.playableMimeTypes);

  @override
  bool get supportsLocalFiles => false;

  @override
  TargetPlaybackState get state => _state;

  @override
  Stream<TargetPlaybackState> get stateStream => _controller.stream;

  @override
  Future<void> load(
    List<TargetTrack> tracks, {
    required int initialIndex,
    required Duration initialPosition,
    required bool autoPlay,
  }) async {
    _tracks
      ..clear()
      ..addAll(tracks);
    _index = initialIndex.clamp(0, tracks.length - 1);
    await _startTrack(_index, position: initialPosition, autoPlay: autoPlay);
  }

  @override
  Future<void> play() async {
    _stopRequested = false;
    await _run(_transport.play);
    _emit(status: PlaybackStatus.playing);
    _startPolling();
  }

  @override
  Future<void> pause() async {
    if (!_transport.supportsPause) return stop();
    await _run(_transport.pause);
    _emit(status: PlaybackStatus.paused);
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;
    _stopPolling();
    await _run(_transport.stopTransport);
    _emit(status: PlaybackStatus.stopped, position: Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    if (!_transport.supportsSeek) return;
    await _run(
      () => _transport.seek(position, unit: _quirks.seekUnit.wireName),
    );
    _emit(position: position);
  }

  @override
  Future<void> skipTo(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    await _startTrack(index, autoPlay: true);
  }

  @override
  Future<void> seekToNext() async {
    if (_index + 1 >= _tracks.length) return stop();
    final started = await _startTrack(_index + 1, autoPlay: true);
    if (!started) _stopPolling();
  }

  @override
  Future<void> seekToPrevious() async {
    if (_state.position > _restartThreshold || _index == 0) {
      return seek(Duration.zero);
    }
    await _startTrack(_index - 1, autoPlay: true);
  }

  @override
  Future<void> setVolume(double level) async {
    final control = renderer.renderingControl;
    if (control == null) return;
    await _run(() => control.setVolume(_quirks.volumeToWire(level).round()));
  }

  @override
  Future<double?> currentVolume() async {
    final control = renderer.renderingControl;
    if (control == null) return null;
    try {
      final value = await _run(control.volume);
      return value == null ? null : _quirks.volumeFromWire(value);
    } on Object catch (error) {
      diagnostics.trail(
        'GetVolume failed',
        category: 'upnp',
        data: {'error': '$error'},
      );
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _stopPolling();
    await _controller.close();
  }

  Future<bool> _startTrack(
    int index, {
    required bool autoPlay,
    Duration position = Duration.zero,
  }) async {
    final track = _tracks.elementAtOrNull(index);
    if (track == null) return false;

    _index = index;
    _sawPlaying = false;
    _stopRequested = false;
    _idlePolls = 0;
    _nextUriSet = null;
    _pollGeneration++;

    _emit(
      status: autoPlay ? PlaybackStatus.buffering : PlaybackStatus.paused,
      position: position,
      currentIndex: index,
      duration: track.duration,
    );

    try {
      if (_quirks.stopBeforeSetUri) await _run(_transport.stopTransport);
      await _run(
        () => _transport.setUri(track.uri, metadata: _metadataFor(track)),
      );
      if (autoPlay) await _run(_transport.play);
      if (position > Duration.zero && _transport.supportsSeek) {
        await _run(
          () => _transport.seek(position, unit: _quirks.seekUnit.wireName),
        );
      }
    } on Object catch (error, stackTrace) {
      unawaited(
        diagnostics.capture(
          error,
          stackTrace: stackTrace,
          operation: 'upnp.setUri',
          tags: _deviceTags,
          extra: {..._deviceInfo, 'mimeType': track.mimeType},
        ),
      );
      _emit(status: PlaybackStatus.error);
      return false;
    }

    await _pushNextUri();
    if (autoPlay) _startPolling();
    return true;
  }

  String _metadataFor(TargetTrack track) => !_quirks.sendTrackMetadata
      ? ''
      : buildDidlLite(
          itemId: track.itemId,
          title: track.title,
          uri: track.uri,
          mimeType: track.mimeType,
          duration: track.duration,
          artist: track.artist,
          album: track.album,
          artUri: track.artUri,
          seekable: _transport.supportsSeek,
        );

  Future<void> _pushNextUri() async {
    if (!_canQueueNextTrack) return;
    final next = _tracks.elementAtOrNull(_index + 1);
    if (next == null) {
      if (_nextUriSet == null) return;
      _nextUriSet = null;
      await _tryNextUri(() => _transport.setNextUri(null));
      return;
    }
    if (_nextUriSet == next.uri) return;
    if (await _tryNextUri(
      () => _transport.setNextUri(next.uri, metadata: _metadataFor(next)),
    )) {
      _nextUriSet = next.uri;
    }
  }

  Future<bool> _tryNextUri(Future<void> Function() action) async {
    try {
      await _run(action);
      return true;
    } on Object catch (error, stackTrace) {
      _nextUriUsable = false;
      _nextUriSet = null;
      unawaited(
        diagnostics.capture(
          error,
          stackTrace: stackTrace,
          operation: 'upnp.setNextUri',
          tags: _deviceTags,
          extra: _deviceInfo,
        ),
      );
      return false;
    }
  }

  void _startPolling() {
    _poll ??= Timer.periodic(pollInterval, (_) => unawaited(_pollOnce()));
  }

  void _stopPolling() {
    _pollGeneration++;
    _poll?.cancel();
    _poll = null;
  }

  @visibleForTesting
  Future<void> pollNow() => _pollOnce();

  Future<void> _pollOnce() async {
    if (_disposed) return;
    final generation = _pollGeneration;
    final AvTransportInfo info;
    final AvPositionInfo positionInfo;
    try {
      info = await _run(_transport.transportInfo);
      positionInfo = await _run(_transport.positionInfo);
      _failures = 0;
    } on Object catch (error, stackTrace) {
      _failures++;
      diagnostics.trail(
        'poll failed ($_failures)',
        category: 'upnp',
        data: {'error': '$error'},
      );
      if (_failures >= _failureLimit) {
        _stopPolling();
        _emit(status: PlaybackStatus.error);
        unawaited(
          diagnostics.capture(
            error,
            stackTrace: stackTrace,
            operation: 'upnp.poll',
            tags: _deviceTags,
            extra: {..._deviceInfo, 'failures': _failures},
          ),
        );
      }
      return;
    }

    if (_disposed || generation != _pollGeneration) return;

    final playedThrough = _adoptTrackFromDevice(positionInfo.trackUri);
    if (info.state.isPlaying) _sawPlaying = true;

    _emit(
      status: _statusOf(info.state),
      position: positionInfo.position,
      duration: positionInfo.trackDuration ?? _currentTrack?.duration,
    );

    try {
      if (playedThrough) await _pushNextUri();
      await _advanceIfEnded(info.state);
    } on Object catch (error, stackTrace) {
      unawaited(
        diagnostics.capture(
          error,
          stackTrace: stackTrace,
          operation: 'upnp.advance',
          tags: _deviceTags,
          extra: {..._deviceInfo, 'index': _index, 'tracks': _tracks.length},
        ),
      );
    }
  }

  Future<void> _advanceIfEnded(AvTransportState state) async {
    if (!state.isIdle || !_sawPlaying || _stopRequested) {
      _idlePolls = 0;
      return;
    }

    _idlePolls++;
    final betweenTracks = _nextUriSet != null;
    if (betweenTracks && _idlePolls < _quirks.idlePollsBeforeAdvance) return;

    await _advanceAfterEnd();
  }

  bool _adoptTrackFromDevice(String? trackUri) {
    if (trackUri == null) return false;
    final playing = Uri.tryParse(trackUri);
    if (playing == null) return false;

    final index = _indexOfUri(playing);
    if (index < 0 || index == _index) return false;

    _index = index;
    _sawPlaying = false;
    _idlePolls = 0;
    return true;
  }

  int _indexOfUri(Uri playing) {
    final exact = _tracks.indexWhere((track) => track.uri == playing);
    if (exact >= 0) return exact;
    return _tracks.indexWhere(
      (track) =>
          track.uri.path == playing.path && track.uri.host == playing.host,
    );
  }

  Future<void> _advanceAfterEnd() async {
    _sawPlaying = false;
    if (_index + 1 >= _tracks.length) {
      _stopPolling();
      _emit(
        status: PlaybackStatus.stopped,
        position: Duration.zero,
        completed: true,
      );
      return;
    }
    final started = await _startTrack(_index + 1, autoPlay: true);
    if (!started) _stopPolling();
  }

  TargetTrack? get _currentTrack => _tracks.elementAtOrNull(_index);

  Map<String, String> get _deviceTags => {
    'upnp.manufacturer': renderer.device.manufacturer ?? 'unknown',
    'upnp.model': renderer.model ?? 'unknown',
  };

  Map<String, Object?> get _quirkInfo => {
    ...renderer.fingerprint.redacted().toJson(),
    'quirks': _quirks.toJson(),
  };

  Map<String, Object?> get _deviceInfo => {
    'supportsNextUri': _transport.supportsNextUri,
    'supportsSeek': _transport.supportsSeek,
    ..._quirkInfo,
  };

  PlaybackStatus _statusOf(AvTransportState state) => switch (state) {
    AvTransportState.playing ||
    AvTransportState.recording => PlaybackStatus.playing,
    AvTransportState.pausedPlayback ||
    AvTransportState.pausedRecording => PlaybackStatus.paused,
    AvTransportState.transitioning => PlaybackStatus.buffering,
    AvTransportState.stopped ||
    AvTransportState.noMediaPresent => PlaybackStatus.stopped,
    AvTransportState.unknown => _state.status,
  };

  void _emit({
    PlaybackStatus? status,
    Duration? position,
    int? currentIndex,
    Duration? duration,
    bool completed = false,
  }) {
    if (_disposed || _controller.isClosed) return;
    _state = TargetPlaybackState(
      status: status ?? _state.status,
      position: position ?? _state.position,
      currentIndex: currentIndex ?? _index,
      duration: duration ?? _state.duration,
      canSeek: _transport.supportsSeek,
      completed: completed,
    );
    _controller.add(_state);
  }

  Future<T> _run<T>(Future<T> Function() action) {
    final result = _commands.then((_) => action());
    _commands = result.then((_) {}, onError: (Object _) {});
    return result;
  }
}
