import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';

class AudioQueueState {
  AudioQueueState({required this.songs, this.currentSong});
  final List<SongDTO> songs;
  final SongDTO? currentSong;
}

class AudioQueueNotifier extends StateNotifier<AudioQueueState> {
  AudioQueueNotifier() : super(AudioQueueState(songs: []));

  // Method to add a song to the queue
  void setNewQueue(List<SongDTO> songs, SongDTO playNowSong) {
    state = AudioQueueState(
      songs: songs,
      currentSong: playNowSong,
    );
  }

  void playNextSongInQueue() {
    state = AudioQueueState(
      songs: state.songs,
      currentSong: nextSong,
    );
  }

  int get currentSongIndex {
    if (state.currentSong == null) return 0;
    final currSong = state.songs.firstWhere((element) => element.id == state.currentSong?.id);
    return state.songs.indexOf(currSong);
  }

  SongDTO? get nextSong {
    if (currentSongIndex == state.songs.length - 1) return null; // We playing(yed) last song

    return state.songs[currentSongIndex + 1];
  }

  // Method to set the currently playing song
  void setCurrentSong(SongDTO song) {
    state = AudioQueueState(
      songs: state.songs,
      currentSong: song,
    );
  }

  // Other methods like removeSong, nextSong, previousSong, etc.
}

final audioQueueProvider = StateNotifierProvider<AudioQueueNotifier, AudioQueueState>((ref) => AudioQueueNotifier());
