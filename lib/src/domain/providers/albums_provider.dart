import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:string_capitalize/string_capitalize.dart';

class AlbumsNotifier extends StateNotifier<AsyncData<ItemsPage>> {
  AlbumsNotifier(
    this.ref,
    this.filterState, {
    this.filters,
  }) : super(const AsyncData(ItemsPage()));

  final StateNotifierProviderRef<AlbumsNotifier, AsyncData<ItemsPage>> ref;
  final Filter filterState;
  final String? filters;

  Future<void> loadMore() async {
    final value = state.value;
    final resp = await ref.read(jellyfinApiProvider).getAlbums(
          userId: ref.read(currentUserProvider)!.userId,
          libraryId: ref.read(currentLibraryProvider)!.id,
          sortOrder: filterState.desc ? 'Descending' : 'Ascending',
          sortBy: filterState.orderBy.name.capitalize(),
          startIndex: (value.currentPage * value.totalPerPage).toString(),
          filters: filters,
        );
    state = AsyncData(
      value.copyWith(
        items: [...value.items, ...resp.data.items],
        currentPage: value.currentPage + 1,
      ),
    );
  }
}

final albumsProvider =
    StateNotifierProvider<AlbumsNotifier, AsyncData<ItemsPage>>(
  (ref) => AlbumsNotifier(
    ref,
    ref.watch(filterProvider),
  )..loadMore(),
);

final favoriteAlbumsProvider =
    StateNotifierProvider<AlbumsNotifier, AsyncData<ItemsPage>>(
  (ref) => AlbumsNotifier(
    ref,
    ref.watch(filterProvider),
    filters: 'IsFavorite',
  )..loadMore(),
);
