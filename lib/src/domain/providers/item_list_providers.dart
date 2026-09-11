import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/artist_scope_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class ItemListNotifier
    extends AutoDisposeFamilyAsyncNotifier<ItemsPage, ItemList> {
  late MediaServerClient _api;
  late Filter _filterState;
  late ArtistScope _artistScope;
  String? _libraryId;

  SortDirection get _direction =>
      sortDirectionOf(descending: _filterState.desc);

  @override
  FutureOr<ItemsPage> build(ItemList arg) async {
    if (ref.watch(isOfflineProvider)) throw const OfflineException();
    _api = ref.watch(mediaServerClientProvider);
    _filterState = ref.watch(filterProvider);
    _artistScope = ref.watch(effectiveArtistScopeProvider);
    _libraryId = ref.watch(currentLibraryProvider).valueOrNull?.id;
    return _fetchItems(startPage: const ItemsPage());
  }

  Future<ItemsPage> _fetchItems({
    int startIndex = 0,
    ItemsPage startPage = const ItemsPage(),
  }) async {
    final resp = await switch (arg) {
      ItemList.albums => _api.getAlbums(
        LibraryQuery(
          libraryId: _libraryId,
          sort: _filterState.orderBy.itemSort,
          direction: _direction,
          startIndex: startIndex,
        ),
      ),
      ItemList.artists => _api.getArtists(
        LibraryQuery(
          sort: _filterState.orderBy.itemSort,
          direction: _direction,
          startIndex: startIndex,
          artistScope: _artistScope,
        ),
      ),
      ItemList.genres => _api.getGenres(
        LibraryQuery(
          libraryId: _libraryId,
          sort: _filterState.orderBy.itemSort,
          direction: _direction,
          startIndex: startIndex,
        ),
      ),
      ItemList.playlists => _api.getPlaylists(
        LibraryQuery(
          sort: _filterState.orderBy.itemSort,
          direction: _direction,
          startIndex: startIndex,
        ),
      ),
      ItemList.songs => _api.getAllSongs(
        LibraryQuery(
          libraryId: _libraryId,
          sort: _filterState.orderBy.itemSort,
          direction: _direction,
          startIndex: startIndex,
        ),
      ),
    };
    return startPage.copyWith(
      items: [...startPage.items, ...resp.items],
      currentPage: startPage.currentPage + 1,
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

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = await AsyncValue.guard(
      () => _fetchItems(
        startIndex: current.currentPage * current.totalPerPage,
        startPage: current,
      ),
    );
  }
}

final itemListProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      ItemListNotifier,
      ItemsPage,
      ItemList
    >(
      ItemListNotifier.new,
    );

final AutoDisposeFamilyAsyncNotifierProvider<
  ItemListNotifier,
  ItemsPage,
  ItemList
>
albumsProvider = itemListProvider(ItemList.albums);

final AutoDisposeFamilyAsyncNotifierProvider<
  ItemListNotifier,
  ItemsPage,
  ItemList
>
artistsProvider = itemListProvider(ItemList.artists);

final AutoDisposeFamilyAsyncNotifierProvider<
  ItemListNotifier,
  ItemsPage,
  ItemList
>
playlistsProvider = itemListProvider(ItemList.playlists);

final AutoDisposeFamilyAsyncNotifierProvider<
  ItemListNotifier,
  ItemsPage,
  ItemList
>
genresProvider = itemListProvider(ItemList.genres);
