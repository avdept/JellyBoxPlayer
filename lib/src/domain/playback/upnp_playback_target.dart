import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/diagnostics/diagnostics.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/didl_lite.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/core/upnp/upnp_soap_client.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:optional_features/upnp_quirks.dart';

class UpnpPlaybackTarget implements PlaybackTarget {
  UpnpPlaybackTarget(
    this.renderer, {
    Duration? pollInterval,
    this.startTimeout = const Duration(seconds: 20),
    this.diagnostics = const Diagnostics(),
  }) : pollInterval = pollInterval ?? renderer.quirks.pollInterval;

  static const _restartThreshold = Duration(seconds: 3);
  static const _transitionBackoff = [
    Duration(milliseconds: 300),
    Duration(milliseconds: 600),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];
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
  var _pendingSeekRefusals = 0;
  var _gaveUpWaiting = false;
  var _pollGeneration = 0;
  var _polling = false;
  var _disposed = false;
  var _queueRefused = false;
  var _queuePositioned = true;
  Duration? _parkedAt;
  AvTransportState? _loggedState;
  bool playsToGroup = false;

  AvTransport get _transport => renderer.avTransport;

  DeviceQueue? get _deviceQueue => _queueRefused ? null : renderer.queueDriver;

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
  StreamTargetProfile get streamProfile {
    return StreamTargetProfile.renderer(
      sinkMimeTypes: renderer.playableMimeTypes,
    ).constrained(
      extensionInPath: _quirks.urlNeedsExtension,
      maxSampleRate: _quirks.maxSampleRate,
      maxBitDepth: _quirks.maxBitDepth,
      maxChannels: _quirks.maxChannels,
    );
  }

  static const radioScheme = 'x-rincon-mp3radio';
  static const _radioMimeTypes = {'audio/mpeg', 'audio/aac'};

  Uri deliveryUri(TargetTrack track) =>
      _quirks.transcodeAsRadio &&
          track.transcoded &&
          track.uri.scheme == 'http' &&
          _radioMimeTypes.contains(track.mimeType.toLowerCase())
      ? track.uri.replace(scheme: radioScheme)
      : track.uri;

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

  Future<void> attach(
    List<TargetTrack> tracks, {
    required int index,
    required Duration position,
    required bool playing,
  }) async {
    _tracks
      ..clear()
      ..addAll(tracks);
    _index = index.clamp(0, tracks.length - 1);
    _sawPlaying = playing;
    _stopRequested = false;
    _idlePolls = 0;
    _gaveUpWaiting = false;
    _pendingSeek = null;
    _pollGeneration++;

    diagnostics.trail(
      're-attached to a live session on ${renderer.model ?? 'a renderer'}',
      category: 'upnp',
    );

    _emit(
      status: playing ? PlaybackStatus.playing : PlaybackStatus.paused,
      position: position,
      currentIndex: _index,
      duration: _currentTrack?.duration,
    );

    await _pushNextUri();
    _startPolling();
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
    _queuePositioned = true;
    _parkedAt = null;
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
          autoPlay && initialPosition > Duration.zero && _canSeek(_currentTrack)
          ? initialPosition
          : null;
      if (!autoPlay) {
        _queuePositioned = false;
        _parkedAt = initialPosition;
      }
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
      _queueRefused = true;
      diagnostics.trail(
        'queue of ${_tracks.length} refused by '
        '${renderer.model ?? 'the renderer'} ($error) at '
        '${_delivery(_currentTrack)}, falling back to one track at a time',
        category: 'upnp',
        data: {'error': '$error', 'tracks': _tracks.length},
      );
      await _startTrack(_index, position: initialPosition, autoPlay: autoPlay);
      return;
    }

    diagnostics.trail(
      'queue handed to ${renderer.model ?? 'a renderer'} at $_index: '
      '${_delivery(_currentTrack)}, resume seek '
      '${_pendingSeek == null ? 'none' : '$_pendingSeek'}',
      category: 'upnp',
      data: {
        'tracks': _tracks.length,
        'autoPlay': autoPlay,
        'positionSeconds': initialPosition.inSeconds,
        'resumeSeek': _pendingSeek != null,
      },
    );
    if (autoPlay) _startPolling();
  }

  QueuedTrack _queuedTrack(TargetTrack track) => QueuedTrack(
    uri: deliveryUri(track),
    mimeType: track.mimeType,
    title: track.title,
    duration: track.duration,
    artist: track.artist,
    album: track.album,
    artUri: track.artUri,
  );

  @override
  Future<void> play() async {
    _stopRequested = false;
    _gaveUpWaiting = false;
    if (_deviceQueue != null && !_queuePositioned) {
      final resumeAt = _parkedAt ?? Duration.zero;
      _pendingSeek = resumeAt > Duration.zero && _canSeek(_currentTrack)
          ? resumeAt
          : null;
      diagnostics.trail(
        'queue was parked at ${_index + 1}; selecting it before Play',
        category: 'upnp',
      );
      await skipTo(_index);
      return;
    }
    final ok = await _command('play', _playWhenReady);
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

  bool _canSeek(TargetTrack? track) =>
      _transport.supportsSeek &&
      (track == null || !track.transcoded || _quirks.seekTranscodes);

  @override
  Future<void> seek(Duration position) async {
    if (!_canSeek(_currentTrack)) {
      diagnostics.trail(
        'seek to $position skipped: ${_delivery(_currentTrack)} is not '
        'seekable here',
        category: 'upnp',
      );
      return;
    }
    final ok = await _command(
      'seek',
      () => _transport.seek(position, unit: _quirks.seekUnit.wireName),
    );
    diagnostics.trail(
      'seek to $position ${ok ? 'accepted' : 'refused'}',
      category: 'upnp',
    );
    if (!ok) return;
    _emit(position: position);
  }

  static String _withoutQuery(String? raw) {
    final uri = Uri.tryParse(raw ?? '');
    if (uri == null || raw == null || raw.isEmpty) return 'no uri';
    if (!uri.hasAuthority) return raw.split('?').first;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port${uri.path}';
  }

  String _delivery(TargetTrack? track) {
    if (track == null) return 'no track';
    final uri = deliveryUri(track);
    final kind = track.transcoded ? 'transcoded' : 'direct';
    final static = uri.queryParameters['static'];
    return '${track.mimeType} $kind ${uri.scheme}://${uri.host}${uri.path}'
        '${static == null ? '' : ' static=$static'}';
  }

  Future<void> _playWhenReady() async {
    for (var attempt = 0; ; attempt++) {
      try {
        await _transport.play();
        return;
      } on UpnpSoapFault catch (fault) {
        if (attempt >= _transitionBackoff.length || fault.errorCode != '701') {
          rethrow;
        }
        diagnostics.trail(
          'device not ready for Play, waiting (${attempt + 1})',
          category: 'upnp',
        );
        await Future<void>.delayed(_transitionBackoff[attempt]);
      }
    }
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
    _queuePositioned = true;
    _parkedAt = null;
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
  }) => insertAll(index, [track], playNext: playNext);

  @override
  Future<void> insertAll(
    int index,
    List<TargetTrack> tracks, {
    bool playNext = false,
  }) async {
    if (tracks.isEmpty) return;
    final at = index.clamp(0, _tracks.length);
    _tracks.insertAll(at, tracks);
    if (at <= _index) _index += tracks.length;

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

  @override
  Future<void> replaceAroundCurrent(
    int currentIndex,
    List<TargetTrack> upcoming,
  ) async {
    if (currentIndex < 0 || currentIndex >= _tracks.length) return;

    final current = _tracks[currentIndex];
    _tracks
      ..clear()
      ..add(current)
      ..addAll(upcoming);
    _index = 0;

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
  Future<void> reorder(
    List<TargetTrack> tracks, {
    required List<int> order,
    required int currentIndex,
  }) async {
    if (tracks.isEmpty) return;
    _tracks
      ..clear()
      ..addAll(tracks);
    _index = currentIndex.clamp(0, _tracks.length - 1);

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

  SpeakerGroups? get _groupVolume => playsToGroup ? renderer.groups : null;

  @override
  Future<void> setVolume(double level) async {
    final wire = _quirks.volumeToWire(level).round();
    final groups = _groupVolume;
    if (groups != null) {
      await _command(
        'setGroupVolume',
        () => groups.setGroupVolume(renderer.id, wire),
      );
      return;
    }
    final control = renderer.renderingControl;
    if (control == null) return;
    await _command('setVolume', () => control.setVolume(wire));
  }

  @override
  Future<double?> currentVolume() async {
    final groups = _groupVolume;
    final control = renderer.renderingControl;
    if (groups == null && control == null) return null;
    try {
      final value = await _run(
        () => groups != null
            ? groups.groupVolume(renderer.id)
            : control!.volume(),
      );
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
        () => _transport.setUri(
          deliveryUri(track),
          metadata: _metadataFor(track),
        ),
      );
      if (autoPlay) await _run(_playWhenReady);
      _pendingSeek = position > Duration.zero && _canSeek(track)
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
          uri: deliveryUri(track),
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
        () => _transport.setNextUri(
          deliveryUri(next),
          metadata: _metadataFor(next),
        ),
      );
    } on Object catch (error, stackTrace) {
      diagnostics.trail(
        'next track ${_delivery(next)} refused: $error',
        category: 'upnp',
        data: {'error': '$error'},
      );
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

  static const _resumeSeekRetries = 3;

  Future<void> _applyPendingSeek() async {
    final position = _pendingSeek;
    if (position == null) return;
    try {
      await _run(
        () => _transport.seek(position, unit: _quirks.seekUnit.wireName),
      );
      _pendingSeek = null;
      _pendingSeekRefusals = 0;
      diagnostics.trail('resume seek to $position accepted', category: 'upnp');
    } on UpnpSoapFault catch (fault) {
      _pendingSeekRefusals++;
      final again =
          fault.errorCode == '701' && _pendingSeekRefusals < _resumeSeekRetries;
      if (!again) {
        _pendingSeek = null;
        _pendingSeekRefusals = 0;
      }
      diagnostics.trail(
        'resume seek refused: $fault'
        '${again ? ', trying again next poll' : ', giving up'}',
        category: 'upnp',
        data: {'error': '$fault', 'attempt': _pendingSeekRefusals},
      );
    } on Object catch (error) {
      _pendingSeek = null;
      _pendingSeekRefusals = 0;
      diagnostics.trail(
        'resume seek refused: $error, giving up',
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
    if (_disposed || _polling) return;
    _polling = true;
    try {
      await _pollDevice();
    } finally {
      _polling = false;
    }
  }

  Future<void> _pollDevice() async {
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
    _logTransition(info.state, positionInfo);
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
      diagnostics.trail(
        'advance from track ${_index + 1}/${_tracks.length} failed: $error',
        category: 'upnp',
        data: {'error': '$error'},
      );
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

  void _logTransition(AvTransportState state, AvPositionInfo position) {
    if (state == _loggedState) return;
    _loggedState = state;
    diagnostics.trail(
      'transport ${state.name} at ${position.position} '
      'track ${_index + 1}/${_tracks.length} '
      '(${_withoutQuery(position.trackUri)})',
      category: 'upnp',
    );
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
    final exact = _tracks.indexWhere(
      (track) => track.uri == playing || deliveryUri(track) == playing,
    );
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
      canSeek: _canSeek(_currentTrack),
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
