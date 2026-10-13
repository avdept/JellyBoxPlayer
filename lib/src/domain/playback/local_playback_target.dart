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

class LocalPlaybackTarget implements PlaybackTarget, SwappableQueue {
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
      _player.currentIndexStream.listen((_) => _emit()),
      _player.positionStream.listen((_) => _emit()),
      _player.durationStream.listen((_) => _emit()),
      _player.playerStateStream.listen((playerState) {
        _scheduleIdleStop(playerState);
        _emit();
      }),
      _player.errorStream.listen(_onPlayerError),
    ];
  }

  static const androidIdleStop = Duration(minutes: 15);
  static const defaultLoadTimeout = Duration(seconds: 15);
  static const defaultStopTimeout = Duration(seconds: 5);

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
  final _shuffleOrder = QueueShuffleOrder();

  late final List<StreamSubscription<Object?>> _subscriptions;

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

  bool get retryPending => _pending != null;

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
    final sources = [for (final track in tracks) _audioSource(track)];
    final loaded = await _setSources(
      sources,
      index: initialIndex,
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
      _needsLoad(index, position);
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
      track: _player.sequence.elementAtOrNull(index),
      index: index,
      position: position,
    );
    debugPrint(
      '[LocalTarget] keeping index $index (${position.inSeconds}s) pending; '
      'wantsPlay=$_wantsPlay online=${_isOnline?.call()} attempt=$_attempt',
    );
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
    final index = _state.currentIndex ?? _player.currentIndex ?? 0;
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
      track: _player.sequence.elementAtOrNull(next),
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
    final sources = [..._player.sequence];
    if (sources.isEmpty) {
      _pending = null;
      _emit();
      return;
    }
    debugPrint('[LocalTarget] retrying the queue after $_attempt failure(s)');
    final loaded = await _setSources(
      sources,
      index: _indexOf(pending),
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
    return sequence.isEmpty ? 0 : pending.index.clamp(0, sequence.length - 1);
  }

  int? _neighbour(_PendingLoad pending, int offset) {
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
      track: _player.sequence.elementAtOrNull(index),
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
      duration: track.duration,
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
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> seekToNext() async {
    final pending = _pending;
    if (pending != null) {
      final next = _neighbour(pending, 1);
      if (next != null) _repoint(next, Duration.zero, 'next');
      return;
    }
    await _player.seekToNext();
  }

  @override
  Future<void> seekToPrevious() async {
    final pending = _pending;
    if (pending != null) {
      final previous = _neighbour(pending, -1);
      final restart =
          previous == null || pending.position > const Duration(seconds: 3);
      _repoint(
        restart ? _indexOf(pending) : previous,
        Duration.zero,
        'previous',
      );
      return;
    }
    await _player.smartSeekToPrevious();
  }

  @override
  Future<void> move(int from, int to) => _player.moveAudioSource(from, to);

  @override
  Future<void> remove(int index) => _player.removeAudioSourceAt(index);

  @override
  Future<void> insert(
    int index,
    TargetTrack track, {
    bool playNext = false,
  }) async {
    if (_player.shuffleModeEnabled) {
      final current = _player.currentIndex;
      _shuffleOrder.nextInsertPosition = playNext && current != null
          ? _shuffleOrder.positionAfterIndex(current)
          : _shuffleOrder.lastPosition;
    }
    await _player.insertAudioSource(index, _audioSource(track));
  }

  @override
  Future<void> replaceAroundCurrent(
    int currentIndex,
    List<TargetTrack> upcoming,
  ) async {
    final length = _player.sequence.length;
    if (currentIndex < 0 || currentIndex >= length) {
      debugPrint('[LocalTarget] queue is out of step; leaving it alone');
      return;
    }

    if (currentIndex + 1 < length) {
      await _player.removeAudioSourceRange(currentIndex + 1, length);
    }
    if (currentIndex > 0) {
      await _player.removeAudioSourceRange(0, currentIndex);
    }
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
    if (index < 0 || index >= _player.sequence.length) {
      debugPrint('[LocalTarget] queue is out of step; skipping a replacement');
      return;
    }

    final position = _shuffleOrder.positionOfIndex(index);
    final pending = _pending;
    final replacesPending = pending != null && index == _indexOf(pending);
    await _player.removeAudioSourceAt(index);
    _shuffleOrder.nextInsertPosition = position;
    await _player.insertAudioSource(index, _audioSource(track));
    if (!replacesPending) return;
    _pending = (
      track: _player.sequence.elementAtOrNull(index),
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
    return uri.host.isEmpty ? uri.scheme : uri.host;
  }

  void _emit() {
    if (_controller.isClosed) return;
    final playerState = _player.playerState;
    final pending = _pending;
    _state = pending != null
        ? TargetPlaybackState(
            status: _wantsPlay
                ? PlaybackStatus.buffering
                : PlaybackStatus.paused,
            position: pending.position,
            currentIndex: _indexOf(pending),
          )
        : TargetPlaybackState(
            status: _statusOf(playerState),
            position: _player.position,
            currentIndex: _player.currentIndex,
            duration: _player.duration,
            bufferedPosition: _player.bufferedPosition,
            completed: playerState.processingState == ProcessingState.completed,
          );
    _controller.add(_state);
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
