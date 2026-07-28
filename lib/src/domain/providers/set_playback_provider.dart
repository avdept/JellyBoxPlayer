import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

enum SetPlaybackResult {
  started,
  empty,
  busy,
}

class SetPlaybackNotifier extends StateNotifier<String?> {
  SetPlaybackNotifier(this._ref) : super(null);

  final Ref _ref;

  String get _userId => _ref.read(currentUserProvider)!.userId;

  Future<SetPlaybackResult> playAlbum(ItemDTO album) => _play(
    setItem: album,
    fetchSongs: () async {
      final resp = await _ref
          .read(jellyfinApiProvider)
          .getSongs(userId: _userId, albumId: album.id);
      return [...resp.data.items]
        ..sort((a, b) => a.indexNumber.compareTo(b.indexNumber));
    },
  );

  Future<SetPlaybackResult> playArtist(ItemDTO artist) => _play(
    setItem: artist,
    fetchSongs: () async {
      final resp = await _ref
          .read(jellyfinApiProvider)
          .getSongsOfSet(userId: _userId, artistIds: [artist.id]);
      return resp.data.items;
    },
  );

  Future<SetPlaybackResult> playGenre(ItemDTO genre) => _play(
    setItem: genre,
    fetchSongs: () async {
      final resp = await _ref.read(jellyfinApiProvider).getSongsOfSet(
        userId: _userId,
        libraryId: _ref.read(currentLibraryProvider).valueOrNull?.id,
        genreIds: [genre.id],
      );
      return resp.data.items;
    },
  );

  Future<SetPlaybackResult> playPlaylist(ItemDTO playlist) => _play(
    setItem: playlist,
    fetchSongs: () async {
      final resp = await _ref
          .read(jellyfinApiProvider)
          .getPlaylistSongs(playlistId: playlist.id, userId: _userId);
      return resp.data.items;
    },
  );

  Future<SetPlaybackResult> _play({
    required ItemDTO setItem,
    required Future<List<ItemDTO>> Function() fetchSongs,
  }) async {
    if (state != null) return SetPlaybackResult.busy;
    state = setItem.id;
    try {
      final songs = await fetchSongs();
      if (songs.isEmpty) return SetPlaybackResult.empty;
      await _ref
          .read(playbackProvider.notifier)
          .play(songs.first, songs, setItem);
      return SetPlaybackResult.started;
    } finally {
      state = null;
    }
  }
}

final setPlaybackProvider =
    StateNotifierProvider<SetPlaybackNotifier, String?>(
      SetPlaybackNotifier.new,
    );
