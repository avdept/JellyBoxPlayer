import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

class AlbumsState {
  AlbumsState({this.items = const [], this.currentPage = 0, this.totalPerPage = 100});
  List<ItemDTO> items = [];
  int currentPage = 0;
  int totalPerPage = 100;

  AlbumsState copyWith({List<ItemDTO> items = const [], int currentPage = 0, int totalPerPage = 100}) {
    return AlbumsState(items: items, currentPage: currentPage, totalPerPage: totalPerPage);
  }
}

class SearchAlbumNotifier extends StateNotifier<AsyncData<AlbumsState>> {
  SearchAlbumNotifier(this.ref, this._searchTerm, AsyncData<AlbumsState> initialState) : super(initialState) {
    ref.listen(searchProvider, (previous, next) {
      _searchTerm = next;
      search();
    });
  }

  StateNotifierProviderRef<SearchAlbumNotifier, AsyncData<AlbumsState>> ref;
  String? _searchTerm;

  Future<void> search() async {
    if (_searchTerm == null || _searchTerm!.isEmpty) {
      state = AsyncData(AlbumsState(items: []));
      return;
    }
    print(_searchTerm);
    final resp = await ref.read(jellyfinApiProvider).searchAlbums(
          userId: ref.read(currentUserProvider.notifier).state!.userId,
          libraryId: ref.read(currentLibraryProvider.notifier).state!.id,
          searchTerm: _searchTerm!,
        );
    state = AsyncData(AlbumsState(items: resp.data.items));
  }
}

//create a global provider as you would normally in riverpod:
final searchAlbumProvider = StateNotifierProvider<SearchAlbumNotifier, AsyncData<AlbumsState>>((ref) {
  return SearchAlbumNotifier(ref, ref.read(searchProvider), AsyncData<AlbumsState>(AlbumsState()));
});
