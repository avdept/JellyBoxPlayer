import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

enum SetPlaybackResult {
  started,
  empty,
  busy,
}

class SetPlaybackNotifier extends StateNotifier<String?> {
  SetPlaybackNotifier(this._ref) : super(null);

  final Ref _ref;

  String get _userId => _ref.read(currentUserProvider)!.userId;

  Future<SetPlaybackResult> playAlbum(LibraryItem album) => _play(
    setItem: album,
    fetchSongs: () => _albumSongs(album.id),
  );

  Future<List<LibraryItem>> _albumSongs(String albumId) async {
    if (!_ref.read(isOfflineProvider)) {
      try {
        final resp = await _ref
            .read(mediaServerClientProvider)
            .getSongs(userId: _userId, albumId: albumId);
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
          .getSongsOfSet(userId: _userId, artistIds: [artist.id]);
      return resp.items;
    },
  );

  Future<SetPlaybackResult> playGenre(LibraryItem genre) => _play(
    setItem: genre,
    fetchSongs: () async {
      final resp = await _ref
          .read(mediaServerClientProvider)
          .getSongsOfSet(
            userId: _userId,
            libraryId: _ref.read(currentLibraryProvider).valueOrNull?.id,
            genreIds: [genre.id],
          );
      return resp.items;
    },
  );

  Future<SetPlaybackResult> playPlaylist(LibraryItem playlist) => _play(
    setItem: playlist,
    fetchSongs: () async {
      final resp = await _ref
          .read(mediaServerClientProvider)
          .getPlaylistSongs(playlistId: playlist.id, userId: _userId);
      return resp.items;
    },
  );

  Future<SetPlaybackResult> playFavouriteSongs(LibraryItem placeholder) =>
      _play(
        setItem: placeholder,
        fetchSongs: () async {
          final resp = await _ref
              .read(mediaServerClientProvider)
              .getAllSongs(
                userId: _userId,
                libraryId: _ref.read(currentLibraryProvider).valueOrNull?.id,
                filters: const ['IsFavorite'],
                limit: '500',
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
