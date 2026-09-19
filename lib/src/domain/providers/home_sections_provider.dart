import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const homeSectionLimit = 20;

final AutoDisposeFutureProvider<List<LibraryItem>>
recentlyPlayedAlbumsProvider = FutureProvider.autoDispose((ref) async {
  if (ref.watch(isOfflineProvider)) throw const OfflineException();
  final api = ref.watch(mediaServerClientProvider);
  final userId = ref.watch(currentUserProvider)?.userId;
  if (userId == null) return const [];

  return api.getRecentlyPlayedAlbums(
    libraryId: ref.watch(currentLibraryProvider).valueOrNull?.id,
    limit: homeSectionLimit,
  );
});

final AutoDisposeFutureProvider<List<LibraryItem>>
frequentlyPlayedAlbumsProvider = FutureProvider.autoDispose((ref) async {
  if (ref.watch(isOfflineProvider)) throw const OfflineException();
  final api = ref.watch(mediaServerClientProvider);
  final userId = ref.watch(currentUserProvider)?.userId;
  if (userId == null) return const [];

  return api.getMostPlayedAlbums(
    libraryId: ref.watch(currentLibraryProvider).valueOrNull?.id,
    limit: homeSectionLimit,
  );
});

final AutoDisposeFutureProvider<List<LibraryItem>> recentlyAddedAlbumsProvider =
    FutureProvider.autoDispose((ref) async {
      if (ref.watch(isOfflineProvider)) throw const OfflineException();
      final api = ref.watch(mediaServerClientProvider);
      final userId = ref.watch(currentUserProvider)?.userId;
      if (userId == null) return const [];

      return api.getLatestAlbums(
        libraryId: ref.watch(currentLibraryProvider).valueOrNull?.id,
        limit: homeSectionLimit,
      );
    });

final AutoDisposeFutureProvider<List<LibraryItem>>
recentlyUpdatedPlaylistsProvider = FutureProvider.autoDispose((ref) async {
  if (ref.watch(isOfflineProvider)) throw const OfflineException();
  final api = ref.watch(mediaServerClientProvider);
  final userId = ref.watch(currentUserProvider)?.userId;
  if (userId == null) return const [];

  final page = await api.getPlaylists(
    const LibraryQuery(
      sort: ItemSort.dateLastContentAdded,
      direction: SortDirection.descending,
      limit: homeSectionLimit,
    ),
  );
  return page.items;
});
