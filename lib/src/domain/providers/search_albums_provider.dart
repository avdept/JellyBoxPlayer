import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

class SearchAlbumsNotifier extends StateNotifier<AsyncData<ItemsPage>> {
  SearchAlbumsNotifier(this.ref, this._searchTerm, AsyncData<ItemsPage> initialState) : super(initialState) {
    ref.listen(searchProvider, (previous, next) {
      _searchTerm = next;
      search();
    });
  }

  StateNotifierProviderRef<SearchAlbumsNotifier, AsyncData<ItemsPage>> ref;
  String? _searchTerm;

  Future<void> search() async {
    if (_searchTerm == null || _searchTerm!.isEmpty) {
      state = const AsyncData(ItemsPage());
      return;
    }

    final resp = await ref.read(jellyfinApiProvider).searchAlbums(
          userId: ref.read(currentUserProvider.notifier).state!.userId,
          libraryId: ref.read(currentLibraryProvider.notifier).state!.id,
          searchTerm: _searchTerm!,
        );
    state = AsyncData(ItemsPage(items: resp.data.items));
  }
}

final searchAlbumProvider = StateNotifierProvider<SearchAlbumsNotifier, AsyncData<ItemsPage>>((ref) {
  return SearchAlbumsNotifier(ref, ref.read(searchProvider), const AsyncData<ItemsPage>(ItemsPage()));
});
