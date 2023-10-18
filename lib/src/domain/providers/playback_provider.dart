// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/queue_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';

enum PlaybackStatus { stopped, paused, playing, buffering, error }

class PlaybackState {
  PlaybackState({
    required this.status,
    required this.position,
    this.totalDuration,
  });

  final PlaybackStatus status;
  final Duration position;
  final Duration? totalDuration;
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  PlaybackNotifier(
    this._ref,
    this._audioPlayer,
  ) : super(PlaybackState(status: PlaybackStatus.stopped, position: Duration.zero)) {
    // Listen for song completion
    _audioPlayer.positionStream.listen((position) {
      state = PlaybackState(
        status: state.status,
        position: position,
        totalDuration: _audioPlayer.duration,
      );
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        print(playerState.processingState);
        _handleSongCompletion();
      }
      // Handle other player states as needed
    });
  }
  final AudioPlayer _audioPlayer;
  final StateNotifierProviderRef<PlaybackNotifier, PlaybackState> _ref;

  Future<void> play(SongDTO playSong, List<SongDTO> songs) async {
    _ref.read(audioQueueProvider.notifier).setNewQueue(songs, playSong);
    try {
      final url =
          'http://jellyfin.home/Audio/${playSong.id}/universal?UserId=${_ref.read(currentUserProvider)}&api_key=5ba1682563d046b6a865bfa8b11fac0f&DeviceId=12345&TranscodingProtocol=http&TranscodingContainer=aac&AudioCodec=aac&Container=mp3,aac,m4a%7Caac,m4b%7Caac,flac,alac,m4a%7Calac,m4b%7Calac,wav,m4a,aiff,aif'; // TODO: Fix this URL
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      state = PlaybackState(status: PlaybackStatus.playing, position: Duration.zero, totalDuration: _audioPlayer.duration);
    } catch (e) {
      state = PlaybackState(status: PlaybackStatus.error, position: Duration.zero);
      // Handle the error as needed
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    state = PlaybackState(
      status: state.status,
      position: position,
      totalDuration: state.totalDuration,
    );
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    state = PlaybackState(status: PlaybackStatus.paused, position: _audioPlayer.position, totalDuration: state.totalDuration);
  }

  Future<void> resume() async {
    await _audioPlayer.play();
    state = PlaybackState(status: PlaybackStatus.playing, position: _audioPlayer.position, totalDuration: state.totalDuration);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = PlaybackState(status: PlaybackStatus.stopped, position: Duration.zero, totalDuration: Duration.zero);
  }

  void _handleSongCompletion() {
    final queueState = _ref.read(audioQueueProvider);
    state = PlaybackState(status: PlaybackStatus.paused, position: Duration.zero, totalDuration: Duration.zero);
    final currentSong = queueState.currentSong;
    final songs = queueState.songs;

    if (currentSong == null) return;

    final currentIndex = songs.indexOf(songs.firstWhere((element) => element == currentSong));
    if (currentIndex != -1 && currentIndex + 1 < songs.length) {
      // There's a next song in the queue
      final nextSong = songs[currentIndex + 1];
      final queue = _ref.read(audioQueueProvider);
      _ref.read(audioQueueProvider.notifier).setCurrentSong(nextSong);
      play(
        nextSong,
        queue.songs,
      ); // Start playing the next song
    } else {
      // Handle the end of the queue (e.g., loop, stop playback, etc.)
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

final playbackProvider = StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) => PlaybackNotifier(ref, ref.read(playerProvider)));
