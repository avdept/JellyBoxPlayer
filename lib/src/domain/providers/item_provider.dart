import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:string_capitalize/string_capitalize.dart';

class AlbumsState {
  AlbumsState({this.items = const [], this.currentPage = 0, this.totalPerPage = 100});
  List<ItemDTO> items = [];
  int currentPage = 0;
  int totalPerPage = 100;

  AlbumsState copyWith({List<ItemDTO> items = const [], int currentPage = 0, int totalPerPage = 100}) {
    return AlbumsState(items: items, currentPage: currentPage, totalPerPage: totalPerPage);
  }
}

class AlbumsNotifier extends StateNotifier<AsyncData<AlbumsState>> {
  AlbumsNotifier(this.ref, this.filterState, AsyncData<AlbumsState> initialState) : super(initialState);

  StateNotifierProviderRef<AlbumsNotifier, AsyncData<AlbumsState>> ref;
  Filter filterState;

  Future<void> loadMore() async {
    final resp = await ref.read(jellyfinApiProvider).getAlbums(
        userId: ref.read(currentUserProvider.notifier).state!.userId,
        libraryId: ref.read(currentLibraryProvider.notifier).state!.id,
        sortOrder: filterState.desc ? 'Descending' : 'Ascending',
        sortBy: filterState.orderBy.name.capitalize(),
        startIndex: (state.value.currentPage * state.value.totalPerPage).toString());
    state = AsyncData(state.value.copyWith(items: [...state.value.items, ...resp.data.items], currentPage: state.value.currentPage + 1));
  }
}

//create a global provider as you would normally in riverpod:
final itemsProvider = StateNotifierProvider<AlbumsNotifier, AsyncData<AlbumsState>>((ref) {
  final prov = AlbumsNotifier(ref, ref.watch(filterProvider), AsyncData<AlbumsState>(AlbumsState()))..loadMore();
  return prov;
});
