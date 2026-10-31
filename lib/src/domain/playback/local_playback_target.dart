import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:jplayer/src/core/audio/queue_shuffle_order.dart';
import 'package:jplayer/src/core/audio/smart_previous.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

typedef _PendingLoad = ({
  IndexedAudioSource? track,
  int index,
  Duration position,
});

class LocalPlaybackTarget
    implements PlaybackTarget, SwappableQueue, LoadFailureReporting {
  LocalPlaybackTarget(
    this._player, {
    Duration? idleStopAfter,
    bool Function()? isOnline,
    Stream<bool> Function()? onlineChanges,
    Future<void> Function()? recheckConnection,
    List<Duration> retryDelays = defaultRetryDelays,
    Duration offlineRetryEvery = const Duration(seconds: 30),
    int skipAfter = 3,
    Duration loadTimeout = defaultLoadTimeout,
    Duration stopTimeout = defaultStopTimeout,
  }) : _idleStopAfter = idleStopAfter,
       _isOnline = isOnline,
       _onlineChanges = onlineChanges,
       _recheckConnection = recheckConnection,
       _retryDelays = retryDelays,
       _offlineRetryEvery = offlineRetryEvery,
       _skipAfter = skipAfter,
       _loadTimeout = loadTimeout,
       _stopTimeout = stopTimeout {
    _subscriptions = [
      _player.currentIndexStream.distinct().listen((index) {
        _emit();
        _onIndexChanged(index);
      }),
      _player.positionStream.listen((_) => _onPosition()),
      _player.durationStream.listen((_) => _emit()),
      _player.playerStateStream.listen((playerState) {
        _scheduleIdleStop(playerState);
        _emit();
      }),
      _player.errorStream.listen(_onPlayerError),
    ];
  }

  static const androidIdleStop = Duration(minutes: 15);

  static const positionInterval = Duration(milliseconds: 200);
  static const defaultLoadTimeout = Duration(seconds: 15);
  static const defaultStopTimeout = Duration(seconds: 5);
  static const queueWindowThreshold = 300;
  static const queueWindowBehind = 30;
  static const queueWindowAhead = 100;
  static const queueWindowMargin = 20;

  static const defaultRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
    Duration(seconds: 30),
  ];

  final AudioPlayer _player;
  final Duration? _idleStopAfter;
  final bool Function()? _isOnline;
  final Stream<bool> Function()? _onlineChanges;
  final Future<void> Function()? _recheckConnection;
  StreamSubscription<bool>? _onlineSubscription;
  final List<Duration> _retryDelays;
  final Duration _offlineRetryEvery;
  final int _skipAfter;
  final Duration _loadTimeout;
  final Duration _stopTimeout;
  final _controller = StreamController<TargetPlaybackState>.broadcast();
  final _failures = StreamController<TrackLoadFailure>.broadcast();
  final _shuffleOrder = QueueShuffleOrder();

  late final List<StreamSubscription<Object?>> _subscriptions;
  final _sincePositionEmit = Stopwatch();

  var _state = TargetPlaybackState.idle;
  var _wantsPlay = false;
  var _generation = 0;
  int? _inFlight;
  var _attempt = 0;
  var _exhausted = false;
  var _disposed = false;
  _PendingLoad? _pending;
  Timer? _retry;
  Timer? _idleStop;
  final _tracks = <TargetTrack>[];
  List<int>? _window;
  Future<void> _windowOps = Future<void>.value();
  var _holdIndex = false;
  int? _lastSlot;

  bool get retryPending => _pending != null;

  @override
  Stream<TrackLoadFailure> get loadFailures => _failures.stream;

  bool get _loading => _inFlight == _generation;

  @override
  bool get holdsCurrentTrack =>
      _pending == null &&
      _player.playerState.processingState != ProcessingState.idle;

  @override
  String get id => 'local';

  @override
  String get name => 'This device';

  @override
  PlaybackTargetKind get kind => PlaybackTargetKind.local;

  @override
  StreamTargetProfile get streamProfile => StreamTargetProfile.localPlayer();

  @override
  bool get supportsLocalFiles => true;

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
    _cancelRetry();
    _pending = null;
    _attempt = 0;
    _exhausted = false;
    _wantsPlay = autoPlay;
    debugPrint(
      '[LocalTarget] loading ${tracks.length} tracks at $initialIndex '
      '(${initialPosition.inSeconds}s, autoPlay=$autoPlay) '
      'from ${_originOf(tracks.elementAtOrNull(initialIndex))}',
    );
    _tracks
      ..clear()
      ..addAll(tracks);
    _lastSlot = null;
    _window = tracks.length > queueWindowThreshold
        ? _windowAround(initialIndex)
        : null;
    if (_window != null) {
      debugPrint(
        '[LocalTarget] big queue: loading a window of ${_window!.length} '
        'around index $initialIndex',
      );
    }
    final loaded = await _setSources(
      _windowSources(),
      index: _playerIndexOf(initialIndex) ?? 0,
      position: initialPosition,
    );
    if (loaded && autoPlay) unawaited(_player.play());
  }

  Future<bool> _setSources(
    List<AudioSource> sources, {
    required int index,
    required Duration position,
  }) async {
    final generation = ++_generation;
    _inFlight = generation;
    bool current() => generation == _generation;
    final clock = Stopwatch()..start();
    try {
      await _player
          .setAudioSources(
            sources,
            initialIndex: index,
            initialPosition: position,
            preload: true,
            shuffleOrder: _shuffleOrder,
          )
          .timeout(_loadTimeout);
      if (!current()) return false;
      debugPrint(
        '[LocalTarget] loaded index $index in ${clock.elapsedMilliseconds}ms',
      );
      _pending = null;
      _attempt = 0;
      return true;
    } on Object catch (error) {
      if (!current()) return false;
      debugPrint(
        error is TimeoutException
            ? '[LocalTarget] load of index $index gave no answer in '
                  '${_loadTimeout.inSeconds}s; stopping the player'
            : '[LocalTarget] load of index $index failed after '
                  '${clock.elapsedMilliseconds}ms: $error',
      );
      await _stopPlayer();
      if (!current()) return false;
      _attempt++;
      _needsLoad(_appIndex(index) ?? index, position);
      return false;
    } finally {
      if (current()) _inFlight = null;
    }
  }

  Future<void> _stopPlayer() async {
    try {
      await _player.stop().timeout(_stopTimeout);
    } on TimeoutException {
      debugPrint(
        '[LocalTarget] the player did not stop in '
        '${_stopTimeout.inSeconds}s; carrying on without it',
      );
    } on Object catch (error) {
      debugPrint('[LocalTarget] stopping the player failed: $error');
    }
  }

  void _needsLoad(int index, Duration position) {
    _pending = (
      track: _sourceAt(index),
      index: index,
      position: position,
    );
    debugPrint(
      '[LocalTarget] keeping index $index (${position.inSeconds}s) pending; '
      'wantsPlay=$_wantsPlay online=${_isOnline?.call()} attempt=$_attempt',
    );
    if (!_failures.isClosed) {
      final tag = _pending?.track?.tag;
      _failures.add((
        itemId: tag is MediaItem ? tag.id : null,
        index: index,
        attempt: _attempt,
      ));
    }
    _syncHold();
    _onlineSubscription ??= _onlineChanges?.call().listen((online) {
      if (online) _restart();
    });
    if (_wantsPlay) unawaited(_recheckConnection?.call());
    _emit();
    _scheduleRetry();
  }

  void _syncHold() {
    if (_pending == null) return;
    if (_wantsPlay) {
      JustAudioBackground.holdPlayback(onCancelled: _onHoldCancelled);
    } else {
      JustAudioBackground.cancelPendingPlayback();
    }
  }

  void _onHoldCancelled() {
    debugPrint('[LocalTarget] the session was paused; retries called off');
    _wantsPlay = false;
    _cancelRetry();
    unawaited(_player.pause());
    _emit();
  }

  Future<void> _onPlayerError(PlayerException error) async {
    if (_loading) return;
    debugPrint(
      '[LocalTarget] player error: ${error.message} '
      '(player ${_player.playerState}, pending=${_pending != null})',
    );
    if (_player.playing) _wantsPlay = true;
    if (_pending != null) {
      _syncHold();
      _emit();
      if (_retry == null) _scheduleRetry();
      return;
    }
    final index = _state.currentIndex ?? _appIndex(_player.currentIndex) ?? 0;
    final position = _state.position;
    await _stopPlayer();
    if (_loading || _pending != null) return;
    _needsLoad(index, position);
  }

  void _scheduleRetry() {
    _cancelRetry();
    if (_disposed || _pending == null || !_wantsPlay) return;
    final online = _isOnline?.call() ?? true;
    if (online && _attempt > _skipAfter && !_skipTrack()) return;
    final delay = _attempt == 0
        ? Duration.zero
        : online
        ? _retryDelays[(_attempt - 1).clamp(0, _retryDelays.length - 1)]
        : _offlineRetryEvery;
    debugPrint(
      '[LocalTarget] retry in ${delay.inSeconds}s after $_attempt '
      'failed attempt(s) (${online ? 'online' : 'offline'})',
    );
    _retry = Timer(delay, () {
      _retry = null;
      unawaited(_attemptLoad());
    });
  }

  bool _skipTrack() {
    final pending = _pending!;
    final next = _neighbour(pending, 1);
    _attempt = 0;
    if (next == null) {
      debugPrint('[LocalTarget] giving up: no playable track left');
      _wantsPlay = false;
      _syncHold();
      _pending = null;
      _exhausted = true;
      _emit();
      return false;
    }
    debugPrint('[LocalTarget] skipping track ${pending.index}, trying $next');
    _pending = (
      track: _sourceAt(next),
      index: next,
      position: Duration.zero,
    );
    _emit();
    return true;
  }

  void _restart({bool interrupt = false}) {
    _attempt = 0;
    if (interrupt) _generation++;
    unawaited(_attemptLoad());
  }

  Future<void> _attemptLoad() async {
    final pending = _pending;
    if (_disposed || pending == null || !_wantsPlay || _loading) return;
    _cancelRetry();
    final List<AudioSource> sources;
    final int index;
    if (_window != null) {
      _window = _windowAround(pending.index);
      sources = _windowSources();
      index = _playerIndexOf(pending.index) ?? 0;
    } else {
      sources = [..._player.sequence];
      index = _indexOf(pending);
    }
    if (sources.isEmpty) {
      _pending = null;
      _emit();
      return;
    }
    debugPrint('[LocalTarget] retrying the queue after $_attempt failure(s)');
    final loaded = await _setSources(
      sources,
      index: index,
      position: pending.position,
    );
    if (!loaded) return;
    _emit();
    if (_wantsPlay) unawaited(_player.play());
  }

  void _cancelRetry() {
    _retry?.cancel();
    _retry = null;
  }

  int _indexOf(_PendingLoad pending) {
    final sequence = _player.sequence;
    final track = pending.track;
    final at = track == null ? -1 : sequence.indexOf(track);
    if (at >= 0) return at;
    if (sequence.isEmpty) return 0;
    final slot = _playerIndexOf(pending.index) ?? pending.index;
    return slot.clamp(0, sequence.length - 1);
  }

  int _pendingAppIndex(_PendingLoad pending) =>
      _window == null ? _indexOf(pending) : pending.index;

  int? _neighbour(_PendingLoad pending, int offset) {
    if (_window != null) {
      final next = pending.index + offset;
      return next >= 0 && next < _tracks.length ? next : null;
    }
    final order = _player.effectiveIndices;
    final at = order.indexOf(_indexOf(pending));
    final slot = at + offset;
    if (at < 0 || slot < 0 || slot >= order.length) return null;
    return order[slot];
  }

  void _repoint(int index, Duration position, String reason) {
    debugPrint(
      '[LocalTarget] $reason while a load is pending: '
      'now index $index at ${position.inSeconds}s',
    );
    _pending = (
      track: _sourceAt(index),
      index: index,
      position: position,
    );
    _emit();
    if (_wantsPlay) _restart(interrupt: true);
  }

  AudioSource _audioSource(TargetTrack track) {
    final tag = MediaItem(
      id: track.itemId,
      album: track.album,
      artist: track.artist,
      duration: track.duration > Duration.zero ? track.duration : null,
      title: track.title,
      extras: track.extras,
      artUri: track.artUri,
    );

    return track.isHls
        ? HlsAudioSource(track.uri, tag: tag)
        : playerAudioSource(track.uri, tag: tag);
  }

  @override
  Future<void> play() async {
    _wantsPlay = true;
    _exhausted = false;
    debugPrint(
      '[LocalTarget] play (pending=${_pending != null}, '
      'player ${_player.playerState})',
    );
    if (_pending != null) {
      _syncHold();
      await _attemptLoad();
      return;
    }
    final playerState = _player.playerState;
    if (playerState.playing &&
        playerState.processingState == ProcessingState.idle) {
      debugPrint(
        '[LocalTarget] the player claims to be playing with nothing loaded; '
        'clearing that before play',
      );
      await _player.pause();
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    debugPrint('[LocalTarget] pause (pending=${_pending != null})');
    _wantsPlay = false;
    _cancelRetry();
    _syncHold();
    if (_pending != null) _emit();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    debugPrint('[LocalTarget] stop (pending=${_pending != null})');
    _wantsPlay = false;
    _cancelRetry();
    _syncHold();
    _pending = null;
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    final pending = _pending;
    if (pending != null) {
      _repoint(_indexOf(pending), position, 'seek');
      return;
    }
    await _player.seek(position);
  }

  @override
  Future<void> skipTo(int index) async {
    if (_pending != null) {
      _repoint(index, Duration.zero, 'skipTo');
      return;
    }
    if (_window == null) {
      await _player.seek(Duration.zero, index: index);
      return;
    }
    await _serial(() async {
      final slot = _playerIndexOf(index);
      if (slot != null) {
        await _player.seek(Duration.zero, index: slot);
        return;
      }
      await _rewindowNow(index, Duration.zero);
    });
  }

  @override
  Future<void> seekToNext() async {
    final pending = _pending;
    if (pending != null) {
      final next = _neighbour(pending, 1);
      if (next != null) _repoint(next, Duration.zero, 'next');
      return;
    }
    if (_window == null) {
      await _player.seekToNext();
      return;
    }
    await _serial(() async {
      await _slide();
      await _player.seekToNext();
    });
  }

  @override
  Future<void> seekToPrevious() async {
    final pending = _pending;
    if (pending != null) {
      final previous = _neighbour(pending, -1);
      final restart =
          previous == null || pending.position > const Duration(seconds: 3);
      _repoint(
        restart ? _pendingAppIndex(pending) : previous,
        Duration.zero,
        'previous',
      );
      return;
    }
    if (_window == null) {
      await _player.smartSeekToPrevious();
      return;
    }
    await _serial(() async {
      await _slide();
      await _player.smartSeekToPrevious();
    });
  }

  @override
  Future<void> move(int from, int to) async {
    final window = _window;
    if (window == null) return _player.moveAudioSource(from, to);
    await _serial(() async {
      if (from < 0 ||
          from >= _tracks.length ||
          to < 0 ||
          to >= _tracks.length) {
        debugPrint('[LocalTarget] queue is out of step; leaving it alone');
        return;
      }
      final fromSlot = window.indexOf(from);
      final toSlot = window.indexOf(to);
      _tracks.insert(to, _tracks.removeAt(from));
      for (var slot = 0; slot < window.length; slot++) {
        final index = window[slot];
        if (index == from) {
          window[slot] = to;
        } else if (from < index && index <= to) {
          window[slot] = index - 1;
        } else if (to <= index && index < from) {
          window[slot] = index + 1;
        }
      }
      if (fromSlot >= 0 && toSlot >= 0) {
        await _player.moveAudioSource(fromSlot, toSlot);
        window.sort();
      } else if (fromSlot >= 0 || toSlot >= 0) {
        await _rebuildAroundCurrent();
      }
    });
    _emitRemapped();
  }

  @override
  Future<void> remove(int index) async {
    final window = _window;
    if (window == null) return _player.removeAudioSourceAt(index);
    await _serial(() async {
      if (index < 0 || index >= _tracks.length) return;
      _tracks.removeAt(index);
      final slot = window.indexOf(index);
      if (slot >= 0) {
        await _player.removeAudioSourceAt(slot);
        window.removeAt(slot);
      }
      for (var i = 0; i < window.length; i++) {
        if (window[i] > index) window[i] = window[i] - 1;
      }
      final pending = _pending;
      if (pending != null && pending.index > index) {
        _pending = (
          track: pending.track,
          index: pending.index - 1,
          position: pending.position,
        );
      }
    });
    _emitRemapped();
  }

  @override
  Future<void> insert(
    int index,
    TargetTrack track, {
    bool playNext = false,
  }) async {
    final window = _window;
    if (window == null) {
      if (_player.shuffleModeEnabled) {
        final current = _player.currentIndex;
        _shuffleOrder.nextInsertPosition = playNext && current != null
            ? _shuffleOrder.positionAfterIndex(current)
            : _shuffleOrder.lastPosition;
      }
      await _player.insertAudioSource(index, _audioSource(track));
      return;
    }
    await _serial(() async {
      if (index < 0 || index > _tracks.length) return;
      final first = window.first;
      final last = window.last;
      _tracks.insert(index, track);
      for (var i = 0; i < window.length; i++) {
        if (window[i] >= index) window[i] = window[i] + 1;
      }
      final pending = _pending;
      if (pending != null && pending.index >= index) {
        _pending = (
          track: pending.track,
          index: pending.index + 1,
          position: pending.position,
        );
      }
      if (index < first || index > last + 1) return;
      final slot = index - first;
      await _player.insertAudioSource(slot, _audioSource(track));
      window.insert(slot, index);
    });
    _emitRemapped();
  }

  void _emitRemapped() {
    if (!_disposed) _emit();
  }

  @override
  Future<void> replaceAroundCurrent(
    int currentIndex,
    List<TargetTrack> upcoming,
  ) async {
    if (_window != null) {
      await _serial(() async {
        final current = _tracks.elementAtOrNull(currentIndex);
        if (current == null) {
          debugPrint('[LocalTarget] queue is out of step; leaving it alone');
          return;
        }
        _tracks
          ..clear()
          ..add(current)
          ..addAll(upcoming);
        await _rebuildAroundCurrent(appIndex: 0);
      });
      return;
    }
    final length = _player.sequence.length;
    if (currentIndex < 0 || currentIndex >= length) {
      debugPrint('[LocalTarget] queue is out of step; leaving it alone');
      return;
    }

    if (currentIndex + 1 < length) {
      await _player.removeAudioSourceRange(currentIndex + 1, length);
    }
    await _removeHead(currentIndex, current: currentIndex);
    if (upcoming.isEmpty) return;
    _shuffleOrder.nextInsertPosition = _shuffleOrder.lastPosition;
    await _player.addAudioSources([
      for (final track in upcoming) _audioSource(track),
    ]);
  }

  @override
  Future<void> reorder(
    List<TargetTrack> tracks, {
    required List<int> order,
    required int currentIndex,
  }) async {
    if (_window != null) {
      await _serial(() async {
        if (order.length != _tracks.length) {
          debugPrint(
            '[LocalTarget] queue is out of step; leaving its order alone',
          );
          return;
        }
        _tracks
          ..clear()
          ..addAll(tracks);
        await _rebuildAroundCurrent(appIndex: currentIndex);
      });
      return;
    }
    if (order.length != _player.sequence.length) {
      debugPrint('[LocalTarget] queue is out of step; leaving its order alone');
      return;
    }

    final positions = [...order];
    for (var slot = 0; slot < positions.length; slot++) {
      final from = positions[slot];
      if (from == slot) continue;
      await _player.moveAudioSource(from, slot);
      for (var rest = slot + 1; rest < positions.length; rest++) {
        final position = positions[rest];
        if (position >= slot && position < from) positions[rest] = position + 1;
      }
      positions[slot] = slot;
    }
  }

  @override
  Future<void> replace(int index, TargetTrack track) async {
    if (_window != null) {
      await _serial(() async {
        if (index >= 0 && index < _tracks.length) _tracks[index] = track;
        await _replaceSlot(index, track);
      });
      return;
    }
    await _replaceSlot(index, track);
  }

  Future<void> _replaceSlot(int index, TargetTrack track) async {
    final slot = _playerIndexOf(index);
    if (slot == null) return;
    if (slot < 0 || slot >= _player.sequence.length) {
      debugPrint('[LocalTarget] queue is out of step; skipping a replacement');
      return;
    }

    final position = _shuffleOrder.positionOfIndex(slot);
    final pending = _pending;
    final replacesPending = pending != null && slot == _indexOf(pending);
    await _player.removeAudioSourceAt(slot);
    _shuffleOrder.nextInsertPosition = position;
    await _player.insertAudioSource(slot, _audioSource(track));
    if (!replacesPending) return;
    _pending = (
      track: _player.sequence.elementAtOrNull(slot),
      index: index,
      position: pending.position,
    );
    _restart();
  }

  @override
  Future<void> setVolume(double level) async {
    try {
      await _player.setVolume(level);
    } on MissingPluginException {
      debugPrint('[LocalTarget] volume noted; player is between sessions');
    }
  }

  @override
  Future<double?> currentVolume() async => _player.volume;

  @override
  Future<void> dispose() async {
    _disposed = true;
    _idleStop?.cancel();
    _cancelRetry();
    await _onlineSubscription?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _failures.close();
    await _controller.close();
  }

  void _scheduleIdleStop(PlayerState playerState) {
    final after = _idleStopAfter;
    if (after == null) return;
    final paused =
        !playerState.playing &&
        playerState.processingState != ProcessingState.idle &&
        playerState.processingState != ProcessingState.completed;
    if (!paused) {
      _idleStop?.cancel();
      _idleStop = null;
      return;
    }
    _idleStop ??= Timer(after, () {
      _idleStop = null;
      if (!_player.playing) unawaited(_player.stop());
    });
  }

  String _originOf(TargetTrack? track) {
    final uri = track?.uri;
    if (uri == null) return 'nothing';
    if (track!.isLocalFile) return 'a local file';
    final location = track.location;
    if (location != null) return 'the server (${location.path})';
    return uri.host.isEmpty ? uri.scheme : uri.host;
  }

  void _onPosition() {
    if (_player.playing &&
        _sincePositionEmit.isRunning &&
        _sincePositionEmit.elapsed < positionInterval) {
      return;
    }
    _emit();
  }

  void _emit() {
    if (_controller.isClosed) return;
    _sincePositionEmit
      ..reset()
      ..start();
    final playerState = _player.playerState;
    final pending = _pending;
    _state = pending != null
        ? TargetPlaybackState(
            status: _wantsPlay
                ? PlaybackStatus.buffering
                : PlaybackStatus.paused,
            position: pending.position,
            currentIndex: _pendingAppIndex(pending),
          )
        : TargetPlaybackState(
            status: _statusOf(playerState),
            position: _player.position,
            currentIndex: _holdIndex
                ? _state.currentIndex
                : _appIndex(_player.currentIndex),
            duration: _player.duration,
            bufferedPosition: _player.bufferedPosition,
            completed: playerState.processingState == ProcessingState.completed,
          );
    _controller.add(_state);
  }

  int? _appIndex(int? slot) {
    if (slot == null) return null;
    final window = _window;
    if (window == null) return slot;
    return slot < window.length ? window[slot] : null;
  }

  int? _playerIndexOf(int index) {
    final window = _window;
    if (window == null) return index;
    final slot = window.indexOf(index);
    return slot < 0 ? null : slot;
  }

  IndexedAudioSource? _sourceAt(int index) {
    final slot = _playerIndexOf(index);
    return slot == null ? null : _player.sequence.elementAtOrNull(slot);
  }

  List<int> _windowAround(int index) {
    final length = _tracks.length;
    if (length == 0) return [];
    final at = index.clamp(0, length - 1);
    final start = (at - queueWindowBehind).clamp(0, length);
    final end = (at + queueWindowAhead + 1).clamp(0, length);
    return [for (var i = start; i < end; i++) i];
  }

  List<AudioSource> _windowSources() {
    final window = _window;
    if (window == null) {
      return [for (final track in _tracks) _audioSource(track)];
    }
    return [for (final index in window) _audioSource(_tracks[index])];
  }

  Future<void> _serial(Future<void> Function() action) {
    final run = _windowOps.then((_) => action()).catchError((Object error) {
      debugPrint('[LocalTarget] queue window update failed: $error');
    });
    _windowOps = run;
    return run;
  }

  void _onIndexChanged(int? slot) {
    final window = _window;
    final previous = _lastSlot;
    _lastSlot = slot;
    if (window == null || slot == null) return;
    if (slot == 0 &&
        previous == window.length - 1 &&
        window.first > 0 &&
        window.length < _tracks.length &&
        _player.loopMode == LoopMode.all) {
      unawaited(_rewindow(0, Duration.zero));
      return;
    }
    unawaited(_serial(_slide));
  }

  Future<void> _rewindow(int index, Duration position) =>
      _serial(() => _rewindowNow(index, position));

  Future<void> _rewindowNow(int index, Duration position) async {
    if (_window == null || _tracks.isEmpty) return;
    final wantsPlay = _player.playing;
    _window = _windowAround(index);
    _lastSlot = null;
    debugPrint('[LocalTarget] moving the queue window to index $index');
    final loaded = await _setSources(
      _windowSources(),
      index: _playerIndexOf(index) ?? 0,
      position: position,
    );
    if (loaded && wantsPlay) unawaited(_player.play());
  }

  Future<void> _slide() async {
    final window = _window;
    if (window == null || _disposed || _loading || _pending != null) return;
    var slot = _player.currentIndex;
    if (slot == null || slot >= window.length) return;
    final length = _tracks.length;

    final ahead = window.length - 1 - slot;
    if (ahead < queueWindowMargin && window.last + 1 < length) {
      final next = [
        for (
          var i = window.last + 1;
          i < length && i <= window.last + queueWindowAhead - ahead;
          i++
        )
          i,
      ];
      await _player.addAudioSources([
        for (final index in next) _audioSource(_tracks[index]),
      ]);
      window.addAll(next);
    }

    if (slot < queueWindowMargin && window.first > 0) {
      final first = (window.first - (queueWindowBehind - slot)).clamp(
        0,
        window.first,
      );
      final previous = [for (var i = first; i < window.first; i++) i];
      _holdIndex = true;
      try {
        await _player.insertAudioSources(0, [
          for (final index in previous) _audioSource(_tracks[index]),
        ]);
        window.insertAll(0, previous);
        slot += previous.length;
      } finally {
        _holdIndex = false;
      }
      _emit();
    }

    final drop = slot - queueWindowBehind;
    if (drop > queueWindowMargin) {
      _holdIndex = true;
      try {
        await _removeHead(drop, current: slot);
        window.removeRange(0, drop);
        slot -= drop;
      } finally {
        _holdIndex = false;
      }
      _emit();
    }

    final excess = window.length - 1 - slot - queueWindowAhead;
    if (excess > queueWindowMargin) {
      await _player.removeAudioSourceRange(
        window.length - excess,
        window.length,
      );
      window.removeRange(window.length - excess, window.length);
    }
  }

  Future<void> _removeHead(int count, {required int current}) async {
    var remaining = count;
    var slot = current;
    while (remaining > 0) {
      var chunk = slot ~/ 2;
      if (chunk < 1) chunk = 1;
      if (chunk > remaining) chunk = remaining;
      await _player.removeAudioSourceRange(0, chunk);
      slot -= chunk;
      remaining -= chunk;
    }
  }

  Future<void> _rebuildAroundCurrent({int? appIndex}) async {
    final window = _window;
    if (window == null) return;
    final slot = _player.currentIndex;
    final length = _player.sequence.length;
    if (slot == null || slot >= length || slot >= window.length) {
      _window = _windowAround(appIndex ?? 0);
      await _setSources(
        _windowSources(),
        index: _playerIndexOf(appIndex ?? 0) ?? 0,
        position: Duration.zero,
      );
      return;
    }
    final current = appIndex ?? window[slot];
    final next = _windowAround(current);
    final at = next.indexOf(current);
    final before = next.sublist(0, at);
    final after = next.sublist(at + 1);
    _holdIndex = true;
    try {
      if (slot + 1 < length) {
        await _player.removeAudioSourceRange(slot + 1, length);
      }
      await _removeHead(slot, current: slot);
      if (before.isNotEmpty) {
        await _player.insertAudioSources(0, [
          for (final index in before) _audioSource(_tracks[index]),
        ]);
      }
      if (after.isNotEmpty) {
        await _player.addAudioSources([
          for (final index in after) _audioSource(_tracks[index]),
        ]);
      }
      _window = next;
      _lastSlot = _player.currentIndex;
    } finally {
      _holdIndex = false;
    }
    _emit();
  }

  PlaybackStatus _statusOf(PlayerState playerState) {
    if (_exhausted) return PlaybackStatus.error;
    if (playerState.playing) {
      return playerState.processingState == ProcessingState.idle
          ? PlaybackStatus.buffering
          : PlaybackStatus.playing;
    }
    return switch (playerState.processingState) {
      ProcessingState.idle => PlaybackStatus.stopped,
      ProcessingState.loading ||
      ProcessingState.buffering => PlaybackStatus.buffering,
      ProcessingState.ready => PlaybackStatus.paused,
      ProcessingState.completed => PlaybackStatus.stopped,
    };
  }
}

AudioSource playerAudioSource(Uri uri, {required MediaItem tag}) =>
    ProgressiveAudioSource(
      uri,
      tag: tag,
      options: const ProgressiveAudioSourceOptions(
        darwinAssetOptions: DarwinAssetOptions(
          preferPreciseDurationAndTiming: true,
        ),
      ),
    );
