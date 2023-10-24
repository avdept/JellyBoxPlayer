import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';

class AudioQueueState {
  AudioQueueState({required this.originalSongs, required this.shuffledSongs, this.currentSong, this.isShuffled = false});
  final List<SongDTO> originalSongs;
  final SongDTO? currentSong;
  final List<SongDTO> shuffledSongs;
  final bool isShuffled;

  List<SongDTO> get songs => isShuffled ? shuffledSongs : originalSongs;
}

class AudioQueueNotifier extends StateNotifier<AudioQueueState> {
  AudioQueueNotifier() : super(AudioQueueState(originalSongs: [], shuffledSongs: []));

  // Method to add a song to the queue
  void setNewQueue(List<SongDTO> songs, SongDTO playNowSong) {
    state = AudioQueueState(
      originalSongs: songs,
      shuffledSongs: state.isShuffled ? (List<SongDTO>.from(songs)..shuffle()) : songs,
      currentSong: playNowSong,
      isShuffled: state.isShuffled,
    );
  }

  void playNextSongInQueue() {
    state = AudioQueueState(
      originalSongs: state.originalSongs, shuffledSongs: state.shuffledSongs,
      currentSong: nextSong,
      isShuffled: state.isShuffled,);
  }

  void toggleShuffle() {
    state.isShuffled ? clearShuffle() : shuffle();
  }

  void shuffle() {
    final shuffled = List<SongDTO>.from(state.originalSongs)..shuffle();

    state = AudioQueueState(
      originalSongs: state.originalSongs,
      shuffledSongs: shuffled,
      currentSong: state.currentSong,
      isShuffled: true,
    );
  }

  // This method will switch back to the original order.
  void clearShuffle() {
    state = AudioQueueState(
      originalSongs: state.originalSongs,
      shuffledSongs: state.shuffledSongs,
      currentSong: state.currentSong,
    );
  }

  int get currentSongIndex {
    if (state.currentSong == null) return 0;
    final currSong = state.songs.firstWhere((element) => element.id == state.currentSong?.id);
    return state.songs.indexOf(currSong);
  }

  SongDTO get nextSong {
    if (currentSongIndex == state.songs.length - 1 || currentSongIndex == -1) return state.songs.first; // We playing(yed) last song

    return state.songs[currentSongIndex + 1];
  }

  SongDTO get prevSong {
    if (currentSongIndex == -1 || currentSongIndex == 0) return state.songs.last; // We playing(yed) first song

    return state.songs[currentSongIndex - 1];
  }

  // Method to set the currently playing song
  void setCurrentSong(SongDTO song) {
    state = AudioQueueState(
      originalSongs: state.originalSongs,
      shuffledSongs: state.shuffledSongs,
      currentSong: song,
      isShuffled: state.isShuffled,
    );
  }

  // Other methods like removeSong, nextSong, previousSong, etc.
}

final audioQueueProvider = StateNotifierProvider<AudioQueueNotifier, AudioQueueState>((ref) => AudioQueueNotifier());
