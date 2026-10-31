import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:jplayer/src/core/audio/smart_previous.dart';
import 'package:just_audio/just_audio.dart';

class JellyBoxAudioHandler extends BaseAudioHandler with SeekHandler {
  JellyBoxAudioHandler(this._player) {
    _player.playbackEventStream.listen((_) => _onPlaybackEvent());
    _player.playerStateStream.listen((_) => _updatePlaybackState());

    _player.sequenceStateStream.listen((sequenceState) {
      final currentItem = sequenceState?.currentSource?.tag;
      if (currentItem is MediaItem &&
          !identical(currentItem, mediaItem.value)) {
        mediaItem.add(currentItem);
      }
    });
  }

  static const positionInterval = Duration(milliseconds: 250);

  final AudioPlayer _player;
  final _sinceUpdate = Stopwatch();

  void _onPlaybackEvent() {
    final last = playbackState.value;
    final positionOnly =
        last.playing == _player.playing &&
        last.processingState == _processingState &&
        last.queueIndex == _player.currentIndex &&
        last.speed == _player.speed;
    if (positionOnly &&
        _player.playing &&
        _sinceUpdate.isRunning &&
        _sinceUpdate.elapsed < positionInterval) {
      return;
    }
    _updatePlaybackState();
  }

  void _updatePlaybackState() {
    _sinceUpdate
      ..reset()
      ..start();
    playbackState.add(_transformEvent());
  }

  AudioProcessingState get _processingState =>
      switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };

  @override
  Future<void> play() async {
    await _player.play();
    _updatePlaybackState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _updatePlaybackState();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.smartSeekToPrevious();

  @override
  Future<void> stop() => _player.stop();

  PlaybackState _transformEvent() {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _processingState,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
    );
  }
}
