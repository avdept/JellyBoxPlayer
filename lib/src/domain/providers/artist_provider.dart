import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:string_capitalize/string_capitalize.dart';

class ArtistState {
  ArtistState({this.items = const [], this.currentPage = 0, this.totalPerPage = 100});
  List<ItemDTO> items = [];
  int currentPage = 0;
  int totalPerPage = 100;

  ArtistState copyWith({List<ItemDTO> items = const [], int currentPage = 0, int totalPerPage = 100}) {
    return ArtistState(items: items, currentPage: currentPage, totalPerPage: totalPerPage);
  }
}

class ArtistsNotifier extends StateNotifier<AsyncData<ArtistState>> {
  ArtistsNotifier(this.ref, this.filterState, AsyncData<ArtistState> initialState) : super(initialState);

  StateNotifierProviderRef<ArtistsNotifier, AsyncData<ArtistState>> ref;
  Filter filterState;

  Future<void> loadMore() async {
    final resp = await ref.read(jellyfinApiProvider).getArtists(
        userId: ref.read(currentUserProvider.notifier).state!.userId,
        sortOrder: filterState.desc ? 'Descending' : 'Ascending',
        sortBy: filterState.orderBy.name.capitalize(),
        startIndex: (state.value.currentPage * state.value.totalPerPage).toString());
    state = AsyncData(state.value.copyWith(items: [...state.value.items, ...resp.data.items], currentPage: state.value.currentPage + 1));
  }
}

//create a global provider as you would normally in riverpod:
final artistsProvider = StateNotifierProvider<ArtistsNotifier, AsyncData<ArtistState>>((ref) {
  final prov = ArtistsNotifier(ref, ref.watch(filterProvider), AsyncData<ArtistState>(ArtistState()))..loadMore();
  return prov;
});
