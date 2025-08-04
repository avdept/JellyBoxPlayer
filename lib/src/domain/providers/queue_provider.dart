import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/dto.dart';

class AudioQueueState {
  AudioQueueState({
    required this.originalSongs,
    required this.shuffledSongs,
    this.album,
    this.currentSong,
    this.isShuffled = false,
  });

  final List<ItemDTO> originalSongs;
  final ItemDTO? currentSong;
  final ItemDTO? album;
  final List<ItemDTO> shuffledSongs;
  final bool isShuffled;

  List<ItemDTO> get songs => isShuffled ? shuffledSongs : originalSongs;
}

class AudioQueueNotifier extends StateNotifier<AudioQueueState> {
  AudioQueueNotifier()
    : super(
        AudioQueueState(originalSongs: [], shuffledSongs: []),
      );

  // Method to add a song to the queue
  void setNewQueue(List<ItemDTO> songs, ItemDTO playNowSong, ItemDTO album) {
    state = AudioQueueState(
      originalSongs: songs,
      shuffledSongs: state.isShuffled
          ? (List<ItemDTO>.from(songs)..shuffle())
          : songs,
      currentSong: playNowSong,
      isShuffled: state.isShuffled,
      album: album,
    );
  }

  void playNextSongInQueue() {
    state = AudioQueueState(
      originalSongs: state.originalSongs,
      shuffledSongs: state.shuffledSongs,
      currentSong: nextSong,
      isShuffled: state.isShuffled,
      album: state.album,
    );
  }

  void toggleShuffle() {
    state.isShuffled ? clearShuffle() : shuffle();
  }

  void shuffle() {
    final shuffled = List<ItemDTO>.from(state.originalSongs)..shuffle();

    state = AudioQueueState(
      originalSongs: state.originalSongs,
      shuffledSongs: shuffled,
      currentSong: state.currentSong,
      album: state.album,
      isShuffled: true,
    );
  }

  // This method will switch back to the original order.
  void clearShuffle() {
    state = AudioQueueState(
      originalSongs: state.originalSongs,
      shuffledSongs: state.shuffledSongs,
      currentSong: state.currentSong,
      album: state.album,
    );
  }

  int get currentSongIndex {
    if (state.currentSong == null) return 0;
    final currSong = state.songs.firstWhere(
      (element) => element.id == state.currentSong?.id,
    );
    return state.songs.indexOf(currSong);
  }

  ItemDTO get nextSong {
    if (currentSongIndex == state.songs.length - 1 || currentSongIndex == -1) {
      return state.songs.first; // We playing(yed) last song
    }

    return state.songs[currentSongIndex + 1];
  }

  ItemDTO get prevSong {
    if (currentSongIndex == -1 || currentSongIndex == 0) {
      return state.songs.last; // We playing(yed) first song
    }

    return state.songs[currentSongIndex - 1];
  }

  // Method to set the currently playing song
  void setCurrentSong(ItemDTO song) {
    state = AudioQueueState(
      originalSongs: state.originalSongs,
      shuffledSongs: state.shuffledSongs,
      currentSong: song,
      album: state.album,
      isShuffled: state.isShuffled,
    );
  }
}

final audioQueueProvider =
    StateNotifierProvider<AudioQueueNotifier, AudioQueueState>(
      (_) => AudioQueueNotifier(),
    );
