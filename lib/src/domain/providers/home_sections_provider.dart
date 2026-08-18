import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const homeSectionLimit = 20;

const _playedSongsScanLimit = 200;

Future<List<LibraryItem>> _albumsByIds(
  MediaServerClient api,
  String userId,
  List<String> albumIds,
) async {
  if (albumIds.isEmpty) return const [];
  final albums = await api.getAlbums(
    userId: userId,
    ids: albumIds,
    limit: '${albumIds.length}',
  );
  final byId = {for (final album in albums.items) album.id: album};
  return [for (final id in albumIds) ?byId[id]];
}

final AutoDisposeFutureProvider<List<LibraryItem>>
recentlyPlayedAlbumsProvider = FutureProvider.autoDispose((ref) async {
  if (ref.watch(isOfflineProvider)) throw const OfflineException();
  final api = ref.watch(mediaServerClientProvider);
  final userId = ref.watch(currentUserProvider)?.userId;
  if (userId == null) return const [];

  final played = await api.getAllSongs(
    userId: userId,
    libraryId: ref.watch(currentLibraryProvider).valueOrNull?.id,
    sortBy: 'DatePlayed',
    sortOrder: 'Descending',
    filters: const ['IsPlayed'],
    limit: '$_playedSongsScanLimit',
  );

  final albumIds = <String>[];
  for (final song in played.items) {
    final albumId = song.albumId;
    if (albumId == null || albumIds.contains(albumId)) continue;
    albumIds.add(albumId);
    if (albumIds.length == homeSectionLimit) break;
  }

  return _albumsByIds(api, userId, albumIds);
});

final AutoDisposeFutureProvider<List<LibraryItem>>
frequentlyPlayedAlbumsProvider = FutureProvider.autoDispose((ref) async {
  if (ref.watch(isOfflineProvider)) throw const OfflineException();
  final api = ref.watch(mediaServerClientProvider);
  final userId = ref.watch(currentUserProvider)?.userId;
  if (userId == null) return const [];

  final played = await api.getAllSongs(
    userId: userId,
    libraryId: ref.watch(currentLibraryProvider).valueOrNull?.id,
    sortBy: 'PlayCount',
    sortOrder: 'Descending',
    filters: const ['IsPlayed'],
    limit: '$_playedSongsScanLimit',
  );

  final playsPerAlbum = <String, int>{};
  for (final song in played.items) {
    final albumId = song.albumId;
    if (albumId == null) continue;
    playsPerAlbum.update(
      albumId,
      (total) => total + song.userData.playCount,
      ifAbsent: () => song.userData.playCount,
    );
  }

  final albumIds = playsPerAlbum.keys.toList()
    ..sort((a, b) => playsPerAlbum[b]!.compareTo(playsPerAlbum[a]!));

  return _albumsByIds(
    api,
    userId,
    albumIds.take(homeSectionLimit).toList(),
  );
});

final AutoDisposeFutureProvider<List<LibraryItem>> recentlyAddedAlbumsProvider =
    FutureProvider.autoDispose((ref) async {
      if (ref.watch(isOfflineProvider)) throw const OfflineException();
      final api = ref.watch(mediaServerClientProvider);
      final userId = ref.watch(currentUserProvider)?.userId;
      if (userId == null) return const [];

      final page = await api.getAlbums(
        userId: userId,
        libraryId: ref.watch(currentLibraryProvider).valueOrNull?.id,
        sortBy: 'DateCreated',
        limit: '$homeSectionLimit',
      );
      return page.items;
    });

final AutoDisposeFutureProvider<List<LibraryItem>>
recentlyUpdatedPlaylistsProvider = FutureProvider.autoDispose((ref) async {
  if (ref.watch(isOfflineProvider)) throw const OfflineException();
  final api = ref.watch(mediaServerClientProvider);
  final userId = ref.watch(currentUserProvider)?.userId;
  if (userId == null) return const [];

  final page = await api.getPlaylists(
    userId: userId,
    sortBy: 'DateLastContentAdded',
    limit: '$homeSectionLimit',
  );
  return page.items;
});
