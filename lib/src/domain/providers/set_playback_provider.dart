import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/instant_mix_provider.dart';
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
    fetchSongs: () => albumSongs(album.id),
  );

  Future<List<LibraryItem>> albumSongs(String albumId) async {
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
      [...songs]..sort(LibraryItem.compareAlbumOrder);

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

  Future<SetPlaybackResult> playInstantMix(InstantMix mix) {
    _ref.read(instantMixesProvider.notifier).touch(mix.item.id);
    return _play(
      setItem: mix.item,
      fetchSongs: () async => mix.songs,
      keepPlaying: mix.seed.kind == ItemKind.song ? mix.seed.id : null,
    );
  }

  Future<SetPlaybackResult> playGeneratedPlaylist(LibraryItem playlist) =>
      _play(
        setItem: playlist,
        fetchSongs: () => generatedPlaylistSongs(playlist.id),
      );

  Future<List<LibraryItem>> generatedPlaylistSongs(String playlistId) =>
      loadGeneratedPlaylistSongs(
        _ref,
        playlistId: playlistId,
        isOffline: _ref.read(isOfflineProvider),
      );

  Future<SetPlaybackResult> playPlaylist(LibraryItem playlist) => _play(
    setItem: playlist,
    fetchSongs: () => playlistSongs(playlist.id),
  );

  Future<List<LibraryItem>> playlistSongs(String playlistId) async {
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
      _play(setItem: placeholder, fetchSongs: favouriteSongs);

  Future<List<LibraryItem>> favouriteSongs() async {
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
  }

  Future<SetPlaybackResult> _play({
    required LibraryItem setItem,
    required Future<List<LibraryItem>> Function() fetchSongs,
    String? keepPlaying,
  }) async {
    if (state != null) return SetPlaybackResult.busy;
    state = setItem.id;
    try {
      final songs = await fetchSongs();
      if (songs.isEmpty) return SetPlaybackResult.empty;
      final playback = _ref.read(playbackProvider.notifier);
      if (keepPlaying != null &&
          _currentSongId() == keepPlaying &&
          await playback.replaceUpcoming(
            songs,
            setItem,
            sourceId: setItem.id,
          )) {
        return SetPlaybackResult.started;
      }
      await playback.play(songs.first, songs, setItem, sourceId: setItem.id);
      return SetPlaybackResult.started;
    } finally {
      state = null;
    }
  }

  String? _currentSongId() {
    final playback = _ref.read(playbackProvider);
    final index = playback.currentMediaIndex;
    return index != null ? playback.songs.elementAtOrNull(index)?.id : null;
  }
}

final setPlaybackProvider = StateNotifierProvider<SetPlaybackNotifier, String?>(
  SetPlaybackNotifier.new,
);
