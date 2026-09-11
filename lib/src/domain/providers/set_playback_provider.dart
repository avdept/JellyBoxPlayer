import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/todays_playlists_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const _setSongsLimit = 300;
const _favouriteSongsLimit = 500;

enum SetPlaybackResult {
  started,
  empty,
  busy,
}

class SetPlaybackNotifier extends StateNotifier<String?> {
  SetPlaybackNotifier(this._ref) : super(null);

  final Ref _ref;

  Future<SetPlaybackResult> playAlbum(LibraryItem album) => _play(
    setItem: album,
    fetchSongs: () => _albumSongs(album.id),
  );

  Future<List<LibraryItem>> _albumSongs(String albumId) async {
    if (!_ref.read(isOfflineProvider)) {
      try {
        final resp = await _ref
            .read(mediaServerClientProvider)
            .getSongs(albumId);
        return _byIndexNumber(resp.items);
      } on Object {}
    }
    final downloaded = await _ref
        .read(downloadDatabaseProvider)
        .getDownloadedSongs(albumId);
    return _byIndexNumber(downloaded.map((s) => s.item).toList());
  }

  List<LibraryItem> _byIndexNumber(List<LibraryItem> songs) =>
      [...songs]..sort((a, b) => a.indexNumber.compareTo(b.indexNumber));

  Future<SetPlaybackResult> playArtist(LibraryItem artist) => _play(
    setItem: artist,
    fetchSongs: () async {
      final resp = await _ref
          .read(mediaServerClientProvider)
          .getSongsOfSet(
            LibraryQuery(
              artistIds: [artist.id],
              sort: ItemSort.albumOrder,
              limit: _setSongsLimit,
            ),
          );
      return resp.items;
    },
  );

  Future<SetPlaybackResult> playGenre(LibraryItem genre) => _play(
    setItem: genre,
    fetchSongs: () async {
      final resp = await _ref
          .read(mediaServerClientProvider)
          .getSongsOfSet(
            LibraryQuery(
              libraryId: _ref.read(currentLibraryProvider).valueOrNull?.id,
              genreIds: [genre.id],
              sort: ItemSort.albumOrder,
              limit: _setSongsLimit,
            ),
          );
      return resp.items;
    },
  );

  Future<SetPlaybackResult> playGeneratedPlaylist(LibraryItem playlist) =>
      _play(
        setItem: playlist,
        fetchSongs: () => loadGeneratedPlaylistSongs(
          _ref,
          playlistId: playlist.id,
          isOffline: _ref.read(isOfflineProvider),
        ),
      );

  Future<SetPlaybackResult> playPlaylist(LibraryItem playlist) => _play(
    setItem: playlist,
    fetchSongs: () => _playlistSongs(playlist.id),
  );

  Future<List<LibraryItem>> _playlistSongs(String playlistId) async {
    if (!_ref.read(isOfflineProvider)) {
      try {
        final resp = await _ref
            .read(mediaServerClientProvider)
            .getPlaylistSongs(playlistId);
        return resp.items;
      } on Object {}
    }
    final downloaded = await _ref
        .read(downloadDatabaseProvider)
        .getDownloadedPlaylistSongs(playlistId);
    return downloaded.map((s) => s.item).toList();
  }

  Future<SetPlaybackResult> playFavouriteSongs(LibraryItem placeholder) =>
      _play(
        setItem: placeholder,
        fetchSongs: () async {
          final resp = await _ref
              .read(mediaServerClientProvider)
              .getAllSongs(
                LibraryQuery(
                  libraryId: _ref.read(currentLibraryProvider).valueOrNull?.id,
                  filters: const {ItemFilterFlag.favorite},
                  limit: _favouriteSongsLimit,
                ),
              );
          return resp.items;
        },
      );

  Future<SetPlaybackResult> _play({
    required LibraryItem setItem,
    required Future<List<LibraryItem>> Function() fetchSongs,
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

final setPlaybackProvider = StateNotifierProvider<SetPlaybackNotifier, String?>(
  SetPlaybackNotifier.new,
);
