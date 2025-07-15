import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

class SearchPlaylistsNotifier extends StateNotifier<AsyncData<ItemsPage>> {
  SearchPlaylistsNotifier(this.ref, this._searchTerm, AsyncData<ItemsPage> initialState) : super(initialState) {
    ref.listen(searchProvider, (previous, next) {
      _searchTerm = next;
      search();
    });
  }

  StateNotifierProviderRef<SearchPlaylistsNotifier, AsyncData<ItemsPage>> ref;
  String? _searchTerm;

  Future<void> search() async {
    if (_searchTerm == null || _searchTerm!.isEmpty) {
      state = const AsyncData(ItemsPage());
      return;
    }

    final resp = await ref.read(jellyfinApiProvider).searchPlaylists(
      userId: ref.read(currentUserProvider.notifier).state!.userId,
      libraryId: ref.read(currentLibraryProvider.notifier).state!.id,
      searchTerm: _searchTerm!,
    );
    state = AsyncData(ItemsPage(items: resp.data.items));
  }
}

final searchPlaylistsProvider = StateNotifierProvider<SearchPlaylistsNotifier, AsyncData<ItemsPage>>((ref) {
  return SearchPlaylistsNotifier(ref, ref.read(searchProvider), const AsyncData<ItemsPage>(ItemsPage()));
});
