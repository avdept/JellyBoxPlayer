import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/didl_lite.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';

class UpnpPlaybackTarget implements PlaybackTarget {
  UpnpPlaybackTarget(
    this.renderer, {
    this.pollInterval = const Duration(seconds: 1),
  });

  static const _restartThreshold = Duration(seconds: 3);
  static const _failureLimit = 3;

  final UpnpRenderer renderer;
  final Duration pollInterval;

  final _controller = StreamController<TargetPlaybackState>.broadcast();
  final _tracks = <TargetTrack>[];

  Future<void> _commands = Future<void>.value();
  Timer? _poll;
  var _index = 0;
  TargetPlaybackState _state = TargetPlaybackState.idle;
  var _sawPlaying = false;
  var _stopRequested = false;
  var _failures = 0;
  var _disposed = false;
  Uri? _nextUriSet;

  AvTransport get _transport => renderer.avTransport;

  @override
  String get id => renderer.id;

  @override
  String get name => renderer.name;

  @override
  PlaybackTargetKind get kind => PlaybackTargetKind.upnp;

  @override
  StreamTargetProfile get streamProfile =>
      StreamTargetProfile.renderer(sinkMimeTypes: renderer.sinkMimeTypes);

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
    await _run(() => _transport.seek(position));
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
    await _startTrack(_index + 1, autoPlay: true);
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
    await _run(() => control.setVolume(level));
  }

  @override
  Future<double?> currentVolume() async {
    final control = renderer.renderingControl;
    if (control == null) return null;
    try {
      return await _run(control.volume);
    } on Object catch (error) {
      debugPrint('[UPnP] GetVolume on $name failed: $error');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _stopPolling();
    await _controller.close();
  }

  Future<void> _startTrack(
    int index, {
    required bool autoPlay,
    Duration position = Duration.zero,
  }) async {
    final track = _tracks.elementAtOrNull(index);
    if (track == null) return;

    _index = index;
    _sawPlaying = false;
    _stopRequested = false;
    _nextUriSet = null;

    _emit(
      status: autoPlay ? PlaybackStatus.buffering : PlaybackStatus.paused,
      position: position,
      currentIndex: index,
      duration: track.duration,
    );

    await _run(
      () => _transport.setUri(track.uri, metadata: _metadataFor(track)),
    );
    if (autoPlay) await _run(_transport.play);
    if (position > Duration.zero && _transport.supportsSeek) {
      await _run(() => _transport.seek(position));
    }
    await _pushNextUri();

    if (autoPlay) _startPolling();
  }

  String _metadataFor(TargetTrack track) => buildDidlLite(
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
    if (!_transport.supportsNextUri) return;
    final next = _tracks.elementAtOrNull(_index + 1);
    if (next == null) {
      if (_nextUriSet == null) return;
      _nextUriSet = null;
      await _run(() => _transport.setNextUri(null));
      return;
    }
    if (_nextUriSet == next.uri) return;
    _nextUriSet = next.uri;
    await _run(
      () => _transport.setNextUri(next.uri, metadata: _metadataFor(next)),
    );
  }

  void _startPolling() {
    _poll ??= Timer.periodic(pollInterval, (_) => unawaited(_pollOnce()));
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _pollOnce() async {
    if (_disposed) return;
    final AvTransportInfo info;
    final AvPositionInfo positionInfo;
    try {
      info = await _run(_transport.transportInfo);
      positionInfo = await _run(_transport.positionInfo);
      _failures = 0;
    } on Object catch (error) {
      _failures++;
      debugPrint('[UPnP] poll of $name failed ($_failures): $error');
      if (_failures >= _failureLimit) {
        _stopPolling();
        _emit(status: PlaybackStatus.error);
      }
      return;
    }

    final playedThrough = _adoptTrackFromDevice(positionInfo.trackUri);
    if (info.state.isPlaying) _sawPlaying = true;

    _emit(
      status: _statusOf(info.state),
      position: positionInfo.position,
      duration: positionInfo.trackDuration ?? _currentTrack?.duration,
    );

    if (playedThrough) await _pushNextUri();

    final ended = info.state.isIdle && _sawPlaying && !_stopRequested;
    if (ended) await _advanceAfterEnd();
  }

  bool _adoptTrackFromDevice(String? trackUri) {
    if (trackUri == null) return false;
    final playing = Uri.tryParse(trackUri);
    if (playing == null) return false;
    if (_currentTrack?.uri == playing) return false;

    final index = _tracks.indexWhere((track) => track.uri == playing);
    if (index < 0 || index == _index) return false;

    _index = index;
    _sawPlaying = false;
    return true;
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
    await _startTrack(_index + 1, autoPlay: true);
  }

  TargetTrack? get _currentTrack => _tracks.elementAtOrNull(_index);

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
