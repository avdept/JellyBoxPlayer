import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/audio/smart_previous.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class LocalPlaybackTarget implements PlaybackTarget {
  LocalPlaybackTarget(this._player) {
    _subscriptions = [
      _player.currentIndexStream.listen((_) => _emit()),
      _player.positionStream.listen((_) => _emit()),
      _player.durationStream.listen((_) => _emit()),
      _player.playerStateStream.listen((_) => _emit()),
    ];
  }

  final AudioPlayer _player;
  final _controller = StreamController<TargetPlaybackState>.broadcast();

  late final List<StreamSubscription<Object?>> _subscriptions;

  var _state = TargetPlaybackState.idle;

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
    final sources = [for (final track in tracks) _audioSource(track)];
    try {
      await _player.setAudioSources(
        sources,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
        preload: true,
      );
    } on Object catch (error) {
      debugPrint('[LocalTarget] retrying after failed load: $error');
      await _player.stop();
      await _player.setAudioSources(
        sources,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
        preload: true,
      );
    }
    if (autoPlay) unawaited(_player.play());
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
        : ProgressiveAudioSource(
            track.uri,
            tag: tag,
            options: const ProgressiveAudioSourceOptions(
              darwinAssetOptions: DarwinAssetOptions(
                preferPreciseDurationAndTiming: true,
              ),
            ),
          );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipTo(int index) => _player.seek(Duration.zero, index: index);

  @override
  Future<void> seekToNext() => _player.seekToNext();

  @override
  Future<void> seekToPrevious() => _player.smartSeekToPrevious();

  @override
  Future<void> setVolume(double level) => _player.setVolume(level);

  @override
  Future<double?> currentVolume() async => _player.volume;

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _controller.close();
  }

  void _emit() {
    if (_controller.isClosed) return;
    final playerState = _player.playerState;
    _state = TargetPlaybackState(
      status: _statusOf(playerState),
      position: _player.position,
      currentIndex: _player.currentIndex,
      duration: _player.duration,
      completed: playerState.processingState == ProcessingState.completed,
    );
    _controller.add(_state);
  }

  PlaybackStatus _statusOf(PlayerState playerState) {
    if (playerState.playing) return PlaybackStatus.playing;
    return switch (playerState.processingState) {
      ProcessingState.idle => PlaybackStatus.stopped,
      ProcessingState.loading ||
      ProcessingState.buffering => PlaybackStatus.buffering,
      ProcessingState.ready => PlaybackStatus.paused,
      ProcessingState.completed => PlaybackStatus.stopped,
    };
  }
}
