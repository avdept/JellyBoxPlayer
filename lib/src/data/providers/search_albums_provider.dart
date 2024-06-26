import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';



class SearchAlbumNotifier extends StateNotifier<AsyncData<ItemState>> {
  SearchAlbumNotifier(this.ref, this._searchTerm, AsyncData<ItemState> initialState) : super(initialState) {
    ref.listen(searchProvider, (previous, next) {
      _searchTerm = next;
      search();
    });
  }

  StateNotifierProviderRef<SearchAlbumNotifier, AsyncData<ItemState>> ref;
  String? _searchTerm;

  Future<void> search() async {
    if (_searchTerm == null || _searchTerm!.isEmpty) {
      state = AsyncData(ItemState(items: []));
      return;
    }

    final resp = await ref.read(jellyfinApiProvider).searchAlbums(
          userId: ref.read(currentUserProvider.notifier).state!.userId,
          libraryId: ref.read(currentLibraryProvider.notifier).state!.id,
          searchTerm: _searchTerm!,
        );
    state = AsyncData(ItemState(items: resp.data.items));
  }
}

final searchAlbumProvider = StateNotifierProvider<SearchAlbumNotifier, AsyncData<ItemState>>((ref) {
  return SearchAlbumNotifier(ref, ref.read(searchProvider), AsyncData<ItemState>(ItemState()));
});
