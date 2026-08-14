import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class SearchItemsNotifier
    extends AutoDisposeFamilyAsyncNotifier<ItemsPage, ItemList> {
  late MediaServerClient _client;
  var _searchTerm = '';

  @override
  FutureOr<ItemsPage> build(ItemList arg) async {
    if (ref.watch(isOfflineProvider)) throw const OfflineException();
    _client = ref.watch(mediaServerClientProvider);

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
        final resp = await _client.searchSongs(
          userId: userId,
          libraryId: libraryId,
          searchTerm: _searchTerm,
        );
        return ItemsPage(items: resp.items);
      case ItemList.artists:
        final resp = await _client.searchArtists(
          userId: userId,
          searchTerm: _searchTerm,
        );
        return ItemsPage(items: resp.items);
      case ItemList.playlists:
        final resp = await _client.searchPlaylists(
          userId: userId,
          libraryId: libraryId ?? '',
          searchTerm: _searchTerm,
        );
        return ItemsPage(items: resp.items);
      default:
        final resp = await _client.searchAlbums(
          userId: userId,
          libraryId: libraryId,
          searchTerm: _searchTerm,
        );
        return ItemsPage(items: resp.items);
    }
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

final searchItemsProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      SearchItemsNotifier,
      ItemsPage,
      ItemList
    >(
      SearchItemsNotifier.new,
    );
