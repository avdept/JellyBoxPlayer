import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class SearchItemsNotifier
    extends AutoDisposeFamilyAsyncNotifier<ItemsPage, ItemList> {
  late JellyfinApi _api;
  var _searchTerm = '';

  @override
  FutureOr<ItemsPage> build(ItemList arg) async {
    if (ref.watch(isOfflineProvider)) throw const OfflineException();
    _api = ref.watch(jellyfinApiProvider);

    final searchQuery = ref.watch(searchProvider)?.trim();

    if (searchQuery == _searchTerm) {
      return state.valueOrNull ?? const ItemsPage();
    }

    _searchTerm = searchQuery ?? '';
    if (_searchTerm.isEmpty) return const ItemsPage();

    final userId = ref.read(currentUserProvider)!.userId;
    final libraryId = ref.read(currentLibraryProvider).valueOrNull?.id;

    switch (arg) {
      case ItemList.songs:
        final resp = await _api.searchSongs(
          userId: userId,
          libraryId: libraryId,
          searchTerm: _searchTerm,
        );
        return ItemsPage(items: resp.data.items);
      case ItemList.artists:
        final resp = await _api.searchArtists(
          userId: userId,
          searchTerm: _searchTerm,
        );
        return ItemsPage(items: resp.data.items);
      case ItemList.playlists:
        final resp = await _api.searchPlaylists(
          userId: userId,
          libraryId: libraryId ?? '',
          searchTerm: _searchTerm,
        );
        return ItemsPage(items: resp.data.items);
      default:
        final resp = await _api.searchAlbums(
          userId: userId,
          libraryId: libraryId,
          searchTerm: _searchTerm,
        );
        return ItemsPage(items: resp.data.items);
    }
  }

  void updateItem(ItemDTO updated) {
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

final searchItemsProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      SearchItemsNotifier,
      ItemsPage,
      ItemList
    >(
      SearchItemsNotifier.new,
    );
