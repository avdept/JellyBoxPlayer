import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:string_capitalize/string_capitalize.dart';

const favouritesLimit = 100;

const likedSongsPlaylistId = 'jellybox:liked-songs';

const likedSongsPlaylist = LibraryItem(
  id: likedSongsPlaylistId,
  name: 'Liked songs',
  kind: ItemKind.playlist,
);

const _favouriteFilter = ['IsFavorite'];

final AutoDisposeFutureProvider<List<LibraryItem>> favouriteAlbumsProvider =
    FutureProvider.autoDispose((ref) async {
      if (ref.watch(isOfflineProvider)) throw const OfflineException();
      final api = ref.watch(mediaServerClientProvider);
      final userId = ref.watch(currentUserProvider)?.userId;
      if (userId == null) return const [];

      final page = await api.getAlbums(
        userId: userId,
        libraryId: ref.watch(currentLibraryProvider).valueOrNull?.id,
        sortBy: 'SortName',
        sortOrder: 'Ascending',
        filters: _favouriteFilter,
        limit: '$favouritesLimit',
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
        userId: userId,
        sortBy: 'SortName',
        sortOrder: 'Ascending',
        filters: _favouriteFilter,
        limit: '$favouritesLimit',
      );
      return page.items;
    });

final AutoDisposeFutureProvider<LibraryPage> favouriteSongsProvider =
    FutureProvider.autoDispose((ref) async {
      if (ref.watch(isOfflineProvider)) throw const OfflineException();
      final api = ref.watch(mediaServerClientProvider);
      final userId = ref.watch(currentUserProvider)?.userId;
      if (userId == null) return const LibraryPage();

      return api.getAllSongs(
        userId: userId,
        libraryId: ref.watch(currentLibraryProvider).valueOrNull?.id,
        sortBy: 'SortName',
        sortOrder: 'Ascending',
        filters: _favouriteFilter,
        limit: '$favouritesLimit',
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
      userId: userId,
      libraryId: _libraryId,
      sortBy: arg.orderBy == EntityFilter.sortName
          ? 'Name'
          : arg.orderBy.name.capitalize(),
      sortOrder: arg.desc ? 'Descending' : 'Ascending',
      filters: _favouriteFilter,
      startIndex: '$startIndex',
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
