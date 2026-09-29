import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;

class PlaybackToggles {
  const PlaybackToggles(this._ref);

  final ProviderContainer _ref;

  Future<void> toggleShuffle() {
    final enabled = _ref.read(playbackProvider).shuffleEnabled;
    return _ref.read(playbackProvider.notifier).setShuffle(enabled: !enabled);
  }

  Future<void> toggleRepeat() {
    final player = _ref.read(playerProvider);
    return player.setLoopMode(
      player.loopMode == LoopMode.off ? LoopMode.all : LoopMode.off,
    );
  }

  Future<void> toggleFavourite() async {
    final state = _ref.read(playbackProvider);
    final index = state.currentMediaIndex;
    final song = index == null ? null : state.songs.elementAtOrNull(index);
    if (song == null || _ref.read(isOfflineProvider)) return;
    final favourite = !song.userData.isFavorite;
    try {
      await _ref
          .read(mediaServerClientProvider)
          .setFavorite(song.id, favorite: favourite);
    } on Object {
      return;
    }
    _ref.invalidate(favouriteSongsProvider);
    _ref
        .read(playbackProvider.notifier)
        .updateSong(
          song.copyWith(
            userData: song.userData.copyWith(isFavorite: favourite),
          ),
        );
  }
}
