import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const favouritesLimit = 100;

const likedSongsName = 'Liked songs';

LibraryItem likedSongsPlaylistFor(String userId) => LibraryItem(
  id: EphemeralPlaylistId.likedSongs(userId),
  name: likedSongsName,
  kind: ItemKind.playlist,
);

bool isLikedSongsId(String id) => EphemeralPlaylistId.isLikedSongs(id);

final favouritesChangedProvider = StateProvider<int>((ref) => 0);

void markFavouritesChanged(Ref ref) =>
    ref.read(favouritesChangedProvider.notifier).state++;

final Provider<LibraryItem?> likedSongsPlaylistProvider = Provider((ref) {
  final userId = ref.watch(currentUserProvider)?.userId;
  return userId == null ? null : likedSongsPlaylistFor(userId);
});

const _favouriteFilter = {ItemFilterFlag.favorite};
const allFavouritesPageSize = 200;

Future<List<LibraryItem>> fetchAllFavouriteSongs(
  MediaServerClient client, {
  String? libraryId,
  ItemSort sort = ItemSort.dateCreated,
  SortDirection direction = SortDirection.descending,
}) async {
  final stable = sort != ItemSort.random;
  final songs = <LibraryItem>[];
  final seen = <String>{};
  var startIndex = 0;
  while (true) {
    final page = await client.getAllSongs(
      LibraryQuery(
        libraryId: libraryId,
        sort: stable ? sort : ItemSort.dateCreated,
        direction: stable ? direction : SortDirection.descending,
        filters: _favouriteFilter,
        startIndex: startIndex,
        limit: allFavouritesPageSize,
      ),
    );
    var added = 0;
    for (final song in page.items) {
      if (seen.add(song.id)) {
        songs.add(song);
        added++;
      }
    }
    startIndex += page.items.length;
    if (added == 0 || page.items.length < allFavouritesPageSize) break;
    if (page.totalRecordCount > 0 && startIndex >= page.totalRecordCount) {
      break;
    }
  }
  return songs;
}

List<LibraryItem> mergeLikedOrder(
  List<String> localIds,
  List<LibraryItem> songs,
) {
  final local = localIds.toSet();
  final byId = {for (final song in songs) song.id: song};
  return [
    for (final song in songs)
      if (!local.contains(song.id)) song,
    for (final id in localIds)
      if (byId[id] case final song?) song,
  ];
}

final AutoDisposeFutureProvider<List<LibraryItem>> favouriteAlbumsProvider =
    FutureProvider.autoDispose((ref) async {
      if (ref.watch(isOfflineProvider)) throw const OfflineException();
      final api = ref.watch(mediaServerClientProvider);
      final userId = ref.watch(currentUserProvider)?.userId;
      if (userId == null) return const [];

      final page = await api.getAlbums(
        LibraryQuery(
          libraryId: ref.watch(currentLibraryProvider).valueOrNull?.id,
          filters: _favouriteFilter,
          limit: favouritesLimit,
        ),
      );
      return page.items;
    });

final AutoDisposeFutureProvider<List<LibraryItem>> favouriteArtistsProvider =
    FutureProvider.autoDispose((ref) async {
      if (ref.watch(isOfflineProvider)) throw const OfflineException();
      final api = ref.watch(mediaServerClientProvider);
      final userId = ref.watch(currentUserProvider)?.userId;
      if (userId == null) return const [];

      final page = await api.getArtists(
        const LibraryQuery(filters: _favouriteFilter, limit: favouritesLimit),
      );
      return page.items;
    });

final AutoDisposeFutureProvider<List<LibraryItem>> favouritePlaylistsProvider =
    FutureProvider.autoDispose((ref) async {
      if (ref.watch(isOfflineProvider)) throw const OfflineException();
      final api = ref.watch(mediaServerClientProvider);
      final userId = ref.watch(currentUserProvider)?.userId;
      if (userId == null) return const [];

      if (!ref.watch(serverCapabilitiesProvider).playlistFavourites) {
        return const [];
      }

      final page = await api.getPlaylists(
        const LibraryQuery(filters: _favouriteFilter, limit: favouritesLimit),
      );
      return page.items;
    });

final AutoDisposeFutureProvider<List<LibraryItem>> homeFavouritesProvider =
    FutureProvider.autoDispose((ref) async {
      final [playlists, albums] = await Future.wait([
        ref.watch(favouritePlaylistsProvider.future),
        ref.watch(favouriteAlbumsProvider.future),
      ]);
      return [...playlists, ...albums];
    });

final AutoDisposeFutureProvider<LibraryPage> favouriteSongsProvider =
    FutureProvider.autoDispose((ref) async {
      if (ref.watch(isOfflineProvider)) throw const OfflineException();
      final api = ref.watch(mediaServerClientProvider);
      final userId = ref.watch(currentUserProvider)?.userId;
      if (userId == null) return const LibraryPage();

      return api.getAllSongs(
        LibraryQuery(
          libraryId: ref.watch(currentLibraryProvider).valueOrNull?.id,
          filters: _favouriteFilter,
          limit: favouritesLimit,
        ),
      );
    });

final AutoDisposeProvider<List<LibraryItem>> likedSongsCoversProvider =
    Provider.autoDispose((ref) {
      final page = ref.watch(favouriteSongsProvider).valueOrNull;
      if (page == null) return const [];

      final seenAlbums = <String>{};
      final picks = <LibraryItem>[];
      for (final song in page.items) {
        if (!song.images.hasCover) continue;
        if (!seenAlbums.add(song.albumId ?? song.id)) continue;
        picks.add(song);
        if (picks.length == 4) break;
      }
      return picks;
    });

class FavouriteSongsNotifier
    extends AutoDisposeFamilyAsyncNotifier<ItemsPage, Filter> {
  late MediaServerClient _api;
  String? _libraryId;
  String? _userId;

  @override
  FutureOr<ItemsPage> build(Filter arg) async {
    if (ref.watch(isOfflineProvider)) throw const OfflineException();
    _api = ref.watch(mediaServerClientProvider);
    _libraryId = ref.watch(currentLibraryProvider).valueOrNull?.id;
    _userId = ref.watch(currentUserProvider)?.userId;
    return _fetch(startPage: const ItemsPage());
  }

  Future<ItemsPage> _fetch({
    int startIndex = 0,
    ItemsPage startPage = const ItemsPage(),
  }) async {
    final userId = _userId;
    if (userId == null) return startPage;

    final page = await _api.getAllSongs(
      LibraryQuery(
        libraryId: _libraryId,
        sort: arg.orderBy.itemSort,
        direction: sortDirectionOf(descending: arg.desc),
        filters: _favouriteFilter,
        startIndex: startIndex,
      ),
    );
    return startPage.copyWith(
      items: [...startPage.items, ...page.items],
      currentPage: startPage.currentPage + 1,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = await AsyncValue.guard(
      () => _fetch(
        startIndex: current.currentPage * current.totalPerPage,
        startPage: current,
      ),
    );
  }

  void updateItem(LibraryItem updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: [
          for (final item in current.items)
            if (item.id == updated.id) updated else item,
        ],
      ),
    );
  }
}

final favouriteSongsListProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      FavouriteSongsNotifier,
      ItemsPage,
      Filter
    >(FavouriteSongsNotifier.new);
