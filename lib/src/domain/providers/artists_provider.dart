import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:string_capitalize/string_capitalize.dart';

class ArtistsNotifier extends StateNotifier<AsyncData<ItemsPage>> {
  ArtistsNotifier(
    this.ref,
    this.filterState, {
    this.filters,
  }) : super(const AsyncData(ItemsPage()));

  final StateNotifierProviderRef<ArtistsNotifier, AsyncData<ItemsPage>> ref;
  final Filter filterState;
  final String? filters;

  Future<void> loadMore() async {
    final value = state.value;
    final resp = await ref.read(jellyfinApiProvider).getArtists(
          userId: ref.read(currentUserProvider)!.userId,
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

final artistsProvider =
    StateNotifierProvider<ArtistsNotifier, AsyncData<ItemsPage>>(
  (ref) => ArtistsNotifier(
    ref,
    ref.watch(filterProvider),
  )..loadMore(),
);

final favoriteArtistsProvider =
    StateNotifierProvider<ArtistsNotifier, AsyncData<ItemsPage>>(
  (ref) => ArtistsNotifier(
    ref,
    ref.watch(filterProvider),
    filters: 'IsFavorite',
  )..loadMore(),
);
