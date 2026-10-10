import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/generated_playlist_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_day_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/instant_mix_provider.dart';
import 'package:jplayer/src/domain/providers/todays_playlists_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const hydrationBatchSize = 100;

class PlaylistSongsSource {
  PlaylistSongsSource(this._ref);

  final Ref _ref;

  Future<List<LibraryItem>> songsOf(String playlistId) async {
    switch (EphemeralPlaylistId.parse(playlistId)?.kind) {
      case EphemeralPlaylistKind.likedSongs:
        return fetchAllFavouriteSongs(
          _ref.read(mediaServerClientProvider),
          libraryId: _ref.read(currentLibraryProvider).valueOrNull?.id,
        );
      case EphemeralPlaylistKind.instantMix:
      case EphemeralPlaylistKind.soundMix:
        final mix = _ref.read(instantMixesProvider.notifier).byId(playlistId);
        return refreshed(mix?.songs ?? await downloadedSnapshot(playlistId));
      case EphemeralPlaylistKind.genreMix:
      case EphemeralPlaylistKind.genreDiscovery:
        return refreshed(await _generatedSnapshot(playlistId));
      case null:
        final page = await _ref
            .read(mediaServerClientProvider)
            .getPlaylistSongs(playlistId);
        return page.items;
    }
  }

  Future<List<LibraryItem>> downloadedSnapshot(String playlistId) async {
    final downloaded = await _ref
        .read(downloadDatabaseProvider)
        .getDownloadedPlaylistSongs(playlistId);
    return [for (final song in downloaded) song.item];
  }

  Future<List<LibraryItem>> _generatedSnapshot(String playlistId) async {
    final userId = _ref.read(currentUserProvider)?.userId;
    if (userId != null) {
      final stored = await _ref
          .read(generatedPlaylistDatabaseProvider)
          .getSongs(
            playlistId: playlistId,
            userId: userId,
            libraryId: _ref.read(currentLibraryProvider).valueOrNull?.id,
            dayKey: _ref.read(currentDayProvider),
          );
      if (stored.isNotEmpty) return stored;
    }
    final downloaded = await downloadedSnapshot(playlistId);
    if (downloaded.isNotEmpty) return downloaded;
    return loadGeneratedPlaylistSongs(
      _ref,
      playlistId: playlistId,
      isOffline: _ref.read(isOfflineProvider),
    );
  }

  Future<List<LibraryItem>> refreshed(List<LibraryItem> snapshot) async {
    if (snapshot.isEmpty || _ref.read(isOfflineProvider)) return snapshot;
    final client = _ref.read(mediaServerClientProvider);
    final byId = <String, LibraryItem>{};
    try {
      for (
        var start = 0;
        start < snapshot.length;
        start += hydrationBatchSize
      ) {
        final batch = snapshot.skip(start).take(hydrationBatchSize);
        final items = await client.getItemsByIds([
          for (final song in batch) song.id,
        ]);
        for (final item in items) {
          byId[item.id] = item;
        }
      }
    } on Object {
      return snapshot;
    }
    if (byId.isEmpty) return snapshot;
    return [
      for (final song in snapshot) byId[song.id] ?? song,
    ];
  }
}

final playlistSongsSourceProvider = Provider<PlaylistSongsSource>(
  PlaylistSongsSource.new,
);

final AutoDisposeFutureProviderFamily<List<LibraryItem>, String>
downloadedPlaylistSongsProvider = FutureProvider.autoDispose.family((
  ref,
  playlistId,
) {
  ref.listen(downloadManagerProvider, (previous, next) {
    if (previous?.valueOrNull != next.valueOrNull) ref.invalidateSelf();
  });
  return ref.watch(playlistSongsSourceProvider).downloadedSnapshot(playlistId);
});
