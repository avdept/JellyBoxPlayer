import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:string_capitalize/string_capitalize.dart';

class PlaylistsNotifier extends StateNotifier<AsyncData<ItemsPage>> {
  PlaylistsNotifier(
    this.ref,
    this.filterState,
    AsyncData<ItemsPage> initialState,
  ) : super(initialState);

  StateNotifierProviderRef<PlaylistsNotifier, AsyncData<ItemsPage>> ref;
  Filter filterState;

  Future<void> loadMore() async {
    final resp = await ref.read(jellyfinApiProvider).getPlaylists(
          userId: ref.read(currentUserProvider.notifier).state!.userId,
          libraryId: ref.read(currentLibraryProvider.notifier).state!.id,
          sortOrder: filterState.desc ? 'Descending' : 'Ascending',
          sortBy: filterState.orderBy.name.capitalize(),
          startIndex:
              (state.value.currentPage * state.value.totalPerPage).toString(),
        );
    state = AsyncData(
      state.value.copyWith(
        items: [...state.value.items, ...resp.data.items],
        currentPage: state.value.currentPage + 1,
      ),
    );
  }
}

final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, AsyncData<ItemsPage>>((ref) {
  final prov = PlaylistsNotifier(
    ref,
    ref.watch(filterProvider),
    const AsyncData<ItemsPage>(ItemsPage()),
  )..loadMore();
  return prov;
});
