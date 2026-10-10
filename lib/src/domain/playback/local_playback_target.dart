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
    List<Duration> retryDelays = defaultRetryDelays,
    Duration offlineRetryEvery = const Duration(seconds: 30),
    int skipAfter = 3,
  }) : _idleStopAfter = idleStopAfter,
       _isOnline = isOnline,
       _onlineChanges = onlineChanges,
       _retryDelays = retryDelays,
       _offlineRetryEvery = offlineRetryEvery,
       _skipAfter = skipAfter {
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
  StreamSubscription<bool>? _onlineSubscription;
  final List<Duration> _retryDelays;
  final Duration _offlineRetryEvery;
  final int _skipAfter;
  Timer? _idleStop;
  Timer? _retryTimer;
  final _controller = StreamController<TargetPlaybackState>.broadcast();
  final _shuffleOrder = QueueShuffleOrder();

  late final List<StreamSubscription<Object?>> _subscriptions;

  var _state = TargetPlaybackState.idle;
  var _wantsPlay = false;
  var _loading = false;
  var _attempt = 0;
  var _failed = false;
  var _disposed = false;
  _PendingLoad? _pending;

  bool get retryPending => _pending != null;

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
    _settle();
    _failed = false;
    _wantsPlay = autoPlay;
    final sources = [for (final track in tracks) _audioSource(track)];
    final loaded = await _setSources(
      sources,
      index: initialIndex,
      position: initialPosition,
    );
    if (!loaded) return;
    if (autoPlay) unawaited(_player.play());
  }

  Future<bool> _setSources(
    List<AudioSource> sources, {
    required int index,
    required Duration position,
  }) async {
    _loading = true;
    try {
      await _player.setAudioSources(
        sources,
        initialIndex: index,
        initialPosition: position,
        preload: true,
        shuffleOrder: _shuffleOrder,
      );
      _attempt = 0;
      _settle();
      return true;
    } on Object catch (error) {
      debugPrint('[LocalTarget] load failed: $error');
      await _player.stop();
      _deferLoad(index: index, position: position);
      return false;
    } finally {
      _loading = false;
    }
  }

  int _indexOf(_PendingLoad pending) {
    final sequence = _player.sequence;
    final track = pending.track;
    final at = track == null ? -1 : sequence.indexOf(track);
    if (at >= 0) return at;
    return sequence.isEmpty ? 0 : pending.index.clamp(0, sequence.length - 1);
  }

  void _deferLoad({required int index, required Duration position}) {
    _pending = (
      track: _player.sequence.elementAtOrNull(index),
      index: index,
      position: position,
    );
    _onlineSubscription ??= _onlineChanges?.call().listen((online) {
      if (online) _retrySoon();
    });
    if (_wantsPlay) {
      JustAudioBackground.holdPlayback(onCancelled: _onHoldCancelled);
      _scheduleRetry();
    } else {
      JustAudioBackground.cancelPendingPlayback();
    }
    _emit();
  }

  void _onHoldCancelled() {
    _wantsPlay = false;
    _cancelRetry();
    unawaited(_player.pause());
    _emit();
  }

  void _onPlayerError(PlayerException error) {
    if (_loading) return;
    debugPrint('[LocalTarget] player error: ${error.message}');
    if (_player.playing) _wantsPlay = true;
    final pending = _pending;
    if (pending != null) {
      if (_wantsPlay && _retryTimer == null) {
        _deferLoad(index: _indexOf(pending), position: pending.position);
      }
      return;
    }
    final index = _state.currentIndex ?? _player.currentIndex ?? 0;
    final position = _state.position;
    unawaited(_player.stop());
    _deferLoad(index: index, position: position);
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_disposed) return;
    final online = _isOnline?.call() ?? true;
    if (online && _attempt >= _skipAfter) {
      _skipBadTrack();
      return;
    }
    final step = _retryDelays[_attempt.clamp(0, _retryDelays.length - 1)];
    final delay = online ? step : _offlineRetryEvery;
    _attempt++;
    _retryTimer = Timer(delay, () => unawaited(_retryNow()));
  }

  void _skipBadTrack() {
    final pending = _pending;
    if (pending == null) return;
    final order = _player.effectiveIndices;
    final at = order.indexOf(_indexOf(pending));
    final next = at >= 0 && at + 1 < order.length ? order[at + 1] : null;
    _attempt = 0;
    if (next == null) {
      debugPrint('[LocalTarget] giving up: no playable track left');
      _settle();
      _failed = true;
      _wantsPlay = false;
      JustAudioBackground.cancelPendingPlayback();
      _emit();
      return;
    }
    debugPrint('[LocalTarget] skipping track ${pending.index}, trying $next');
    _pending = (
      track: _player.sequence.elementAtOrNull(next),
      index: next,
      position: Duration.zero,
    );
    _emit();
    _retryTimer = Timer(Duration.zero, () => unawaited(_retryNow()));
  }

  void _retrySoon() {
    if (_disposed || _pending == null || !_wantsPlay || _loading) return;
    _attempt = 0;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration.zero, () => unawaited(_retryNow()));
  }

  Future<void> _retryNow() async {
    final pending = _pending;
    if (_disposed || pending == null || !_wantsPlay || _loading) return;
    final sources = [..._player.sequence];
    if (sources.isEmpty) {
      _settle();
      _emit();
      return;
    }
    debugPrint('[LocalTarget] retrying the queue, attempt $_attempt');
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
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _settle() {
    _pending = null;
    unawaited(_onlineSubscription?.cancel());
    _onlineSubscription = null;
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
    _failed = false;
    if (_pending != null) {
      JustAudioBackground.holdPlayback(onCancelled: _onHoldCancelled);
      _attempt = 0;
      _cancelRetry();
      await _retryNow();
      return;
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    _wantsPlay = false;
    _cancelRetry();
    if (_pending != null) {
      JustAudioBackground.cancelPendingPlayback();
      _emit();
    }
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _wantsPlay = false;
    _cancelRetry();
    if (_pending != null) {
      _settle();
      JustAudioBackground.cancelPendingPlayback();
    }
    await _player.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipTo(int index) => _player.seek(Duration.zero, index: index);

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
    await _player.removeAudioSourceAt(index);
    _shuffleOrder.nextInsertPosition = position;
    await _player.insertAudioSource(index, _audioSource(track));
  }

  @override
  Future<void> seekToNext() => _player.seekToNext();

  @override
  Future<void> seekToPrevious() => _player.smartSeekToPrevious();

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
    if (_failed) return PlaybackStatus.error;
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
