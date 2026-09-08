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
    this.startTimeout = const Duration(seconds: 20),
    this.diagnostics = const Diagnostics(),
  }) : pollInterval = pollInterval ?? renderer.quirks.pollInterval;

  static const _restartThreshold = Duration(seconds: 3);
  static const _failureLimit = 3;

  final UpnpRenderer renderer;
  final Duration startTimeout;
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
  DateTime? _waitingSince;
  Duration? _pendingSeek;
  var _gaveUpWaiting = false;
  var _pollGeneration = 0;
  var _disposed = false;

  AvTransport get _transport => renderer.avTransport;

  DeviceQueue? get _deviceQueue => renderer.queueDriver;

  DeviceQuirks get _quirks => renderer.quirks;

  bool get _canQueueNextTrack =>
      _deviceQueue == null &&
      _quirks.queueNextTrack &&
      _transport.supportsNextUri;

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

    final queue = _deviceQueue;
    if (queue == null) {
      await _startTrack(_index, position: initialPosition, autoPlay: autoPlay);
      return;
    }
    await _handOverQueue(
      queue,
      initialPosition: initialPosition,
      autoPlay: autoPlay,
    );
  }

  Future<void> _handOverQueue(
    DeviceQueue queue, {
    required Duration initialPosition,
    required bool autoPlay,
  }) async {
    _sawPlaying = false;
    _stopRequested = false;
    _idlePolls = 0;
    _gaveUpWaiting = false;
    _pollGeneration++;
    _emit(
      status: autoPlay ? PlaybackStatus.buffering : PlaybackStatus.paused,
      position: initialPosition,
      currentIndex: _index,
      duration: _currentTrack?.duration,
    );

    try {
      await _run(
        () => queue.load(
          [for (final track in _tracks) _queuedTrack(track)],
          startIndex: _index,
          autoPlay: autoPlay,
        ),
      );
      _pendingSeek =
          autoPlay && initialPosition > Duration.zero && _transport.supportsSeek
          ? initialPosition
          : null;
    } on Object catch (error, stackTrace) {
      unawaited(
        diagnostics.capture(
          error,
          stackTrace: stackTrace,
          operation: 'upnp.queue.load',
          tags: _deviceTags,
          extra: {
            ..._deviceInfo,
            'tracks': _tracks.length,
            ..._streamInfo(_currentTrack),
          },
        ),
      );
      _emit(status: PlaybackStatus.error);
      return;
    }

    if (autoPlay) _startPolling();
  }

  QueuedTrack _queuedTrack(TargetTrack track) => QueuedTrack(
    uri: track.uri,
    mimeType: track.mimeType,
    title: track.title,
    duration: track.duration,
    artist: track.artist,
    album: track.album,
  );

  @override
  Future<void> play() async {
    _stopRequested = false;
    _gaveUpWaiting = false;
    final ok = await _command('play', () => _transport.play());
    if (!ok) return;
    _emit(status: PlaybackStatus.playing);
    _startPolling();
  }

  @override
  Future<void> pause() async {
    if (!_transport.supportsPause) return stop();
    final ok = await _command('pause', () => _transport.pause());
    if (!ok) return;
    _emit(status: PlaybackStatus.paused);
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;
    _stopPolling();
    await _command('stop', () => _transport.stopTransport());
    _emit(status: PlaybackStatus.stopped, position: Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    if (!_transport.supportsSeek) return;
    final ok = await _command(
      'seek',
      () => _transport.seek(position, unit: _quirks.seekUnit.wireName),
    );
    if (!ok) return;
    _emit(position: position);
  }

  Future<bool> _command(String name, Future<void> Function() action) async {
    try {
      await _run(action);
      return true;
    } on Object catch (error, stackTrace) {
      unawaited(
        _reportFault(error, stackTrace, 'upnp.$name', {
          'state': _state.status.name,
        }),
      );
      unawaited(_resync());
      return false;
    }
  }

  Map<String, Object?> _streamInfo(TargetTrack? track) => {
    'mimeType': track?.mimeType ?? 'unknown',
    'transcoded': track?.transcoded ?? false,
    'isHls': track?.isHls ?? false,
    'streamHost': track == null
        ? 'none'
        : '${track.uri.scheme}://${track.uri.host}:${track.uri.port}',
  };

  Future<void> _reportFault(
    Object error,
    StackTrace stackTrace,
    String operation,
    Map<String, Object?> extra,
  ) {
    diagnostics.trail(
      'cast failed: ${extra['streamHost'] ?? 'unknown host'}'
      ' (${extra['mimeType'] ?? 'unknown type'})',
      category: 'upnp',
      data: extra,
    );
    return diagnostics.capture(
      error,
      stackTrace: stackTrace,
      operation: operation,
      tags: _deviceTags,
      extra: {..._deviceInfo, ...extra},
    );
  }

  Future<void> _resync() async {
    if (_disposed) return;
    try {
      final info = await _run(_transport.transportInfo);
      final position = await _run(_transport.positionInfo);
      _emit(
        status: _statusOf(info.state),
        position: position.position,
        duration: position.trackDuration ?? _currentTrack?.duration,
      );
    } on Object {
      return;
    }
  }

  @override
  Future<void> skipTo(int index) async {
    if (index < 0 || index >= _tracks.length) return;

    final queue = _deviceQueue;
    if (queue == null) {
      await _startTrack(index, autoPlay: true);
      return;
    }

    _index = index;
    _sawPlaying = false;
    _idlePolls = 0;
    _gaveUpWaiting = false;
    _emit(
      status: PlaybackStatus.buffering,
      currentIndex: index,
      duration: _currentTrack?.duration,
    );
    final ok = await _command('queue.skipTo', () => queue.skipTo(index));
    if (!ok) return;
    _startPolling();
  }

  @override
  Future<void> move(int from, int to) async {
    if (from == to) return;
    if (from < 0 || from >= _tracks.length) return;
    if (to < 0 || to >= _tracks.length) return;

    _tracks.insert(to, _tracks.removeAt(from));
    _index = _movedIndex(_index, from, to);

    final queue = _deviceQueue;
    if (queue == null) {
      _emit(currentIndex: _index, duration: _currentTrack?.duration);
      return;
    }

    await _handOverQueue(
      queue,
      initialPosition: _state.position,
      autoPlay: _state.status.isPlaying,
    );
  }

  @override
  Future<void> remove(int index) async {
    if (index < 0 || index >= _tracks.length) return;

    final wasCurrent = index == _index;
    _tracks.removeAt(index);
    if (_tracks.isEmpty) return stop();
    if (index < _index) {
      _index -= 1;
    } else if (wasCurrent) {
      _index = _index.clamp(0, _tracks.length - 1);
    }

    final queue = _deviceQueue;
    if (queue != null) {
      await _handOverQueue(
        queue,
        initialPosition: Duration.zero,
        autoPlay: _state.status.isPlaying,
      );
      return;
    }

    if (wasCurrent) {
      await _startTrack(_index, autoPlay: _state.status.isPlaying);
      return;
    }
    _emit(currentIndex: _index, duration: _currentTrack?.duration);
  }

  @override
  Future<void> insert(
    int index,
    TargetTrack track, {
    bool playNext = false,
  }) async {
    final at = index.clamp(0, _tracks.length);
    _tracks.insert(at, track);
    if (at <= _index) _index += 1;

    final queue = _deviceQueue;
    if (queue != null) {
      await _handOverQueue(
        queue,
        initialPosition: _state.position,
        autoPlay: _state.status.isPlaying,
      );
      return;
    }
    _emit(currentIndex: _index, duration: _currentTrack?.duration);
  }

  int _movedIndex(int index, int from, int to) {
    if (index == from) return to;
    if (from < to && index > from && index <= to) return index - 1;
    if (from > to && index >= to && index < from) return index + 1;
    return index;
  }

  @override
  Future<void> seekToNext() async {
    if (_index + 1 >= _tracks.length) return stop();
    await skipTo(_index + 1);
  }

  @override
  Future<void> seekToPrevious() async {
    if (_state.position > _restartThreshold || _index == 0) {
      return seek(Duration.zero);
    }
    await skipTo(_index - 1);
  }

  @override
  Future<void> setVolume(double level) async {
    final control = renderer.renderingControl;
    if (control == null) return;
    await _command(
      'setVolume',
      () => control.setVolume(_quirks.volumeToWire(level).round()),
    );
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
        'GetVolume failed: $error',
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
    _gaveUpWaiting = false;
    _pendingSeek = null;
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
      _pendingSeek = position > Duration.zero && _transport.supportsSeek
          ? position
          : null;
    } on Object catch (error, stackTrace) {
      unawaited(
        _reportFault(error, stackTrace, 'upnp.setUri', _streamInfo(track)),
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
          seekable: _transport.supportsSeek && !track.transcoded,
          transcoded: track.transcoded,
        );

  Future<void> _pushNextUri() async {
    if (!_canQueueNextTrack) return;
    final next = _tracks.elementAtOrNull(_index + 1);
    if (next == null) return;

    try {
      await _run(
        () => _transport.setNextUri(next.uri, metadata: _metadataFor(next)),
      );
    } on Object catch (error, stackTrace) {
      unawaited(
        diagnostics.capture(
          error,
          stackTrace: stackTrace,
          operation: 'upnp.setNextUri',
          tags: _deviceTags,
          extra: _deviceInfo,
        ),
      );
    }
  }

  Future<void> _applyPendingSeek() async {
    final position = _pendingSeek;
    if (position == null) return;
    _pendingSeek = null;
    try {
      await _run(
        () => _transport.seek(position, unit: _quirks.seekUnit.wireName),
      );
    } on Object catch (error) {
      diagnostics.trail(
        'resume seek refused: $error',
        category: 'upnp',
        data: {'error': '$error'},
      );
    }
  }

  bool _stalled(AvTransportState state) {
    if (_gaveUpWaiting) return true;
    if (state != AvTransportState.transitioning) {
      _waitingSince = null;
      return false;
    }

    final since = _waitingSince ??= DateTime.now();
    if (DateTime.now().difference(since) < startTimeout) return false;

    _stopPolling();
    _waitingSince = null;
    _gaveUpWaiting = true;
    _emit(status: PlaybackStatus.error);
    diagnostics.trail(
      'cast failed: never left TRANSITIONING, '
      '${_currentTrack?.uri.host ?? 'no track'}',
      category: 'upnp',
      data: _streamInfo(_currentTrack),
    );
    unawaited(
      diagnostics.capture(
        StateError('renderer never left TRANSITIONING'),
        operation: 'upnp.stalled',
        tags: _deviceTags,
        extra: {
          ..._deviceInfo,
          'waitedSeconds': startTimeout.inSeconds,
          ..._streamInfo(_currentTrack),
        },
      ),
    );
    return true;
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
        'poll failed ($_failures): $error',
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
    if (_stalled(info.state)) return;
    if (info.state.isPlaying) await _applyPendingSeek();

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
    if (_deviceQueue != null) {
      _idlePolls = 0;
      return;
    }
    if (!state.isIdle || !_sawPlaying || _stopRequested) {
      _idlePolls = 0;
      return;
    }

    _idlePolls++;
    if (_canQueueNextTrack && _idlePolls < _quirks.idlePollsBeforeAdvance) {
      return;
    }

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

  Map<String, Object?> get _deviceInfo => {
    ...renderer.fingerprint.redacted().toJson(),
    'quirks': _quirks.toJson(),
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
