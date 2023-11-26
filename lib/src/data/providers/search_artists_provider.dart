import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';


class SearchArtistsNotifier extends StateNotifier<AsyncData<ItemState>> {
  SearchArtistsNotifier(this.ref, this._searchTerm, AsyncData<ItemState> initialState) : super(initialState) {
    ref.listen(searchProvider, (previous, next) {
      _searchTerm = next;
      search();
    });
  }

  StateNotifierProviderRef<SearchArtistsNotifier, AsyncData<ItemState>> ref;
  String? _searchTerm;

  Future<void> search() async {
    if (_searchTerm == null || _searchTerm!.isEmpty) {
      state = AsyncData(ItemState(items: []));
      return;
    }
    final resp = await ref.read(jellyfinApiProvider).searchArtists(
          userId: ref.read(currentUserProvider.notifier).state!.userId,
          searchTerm: _searchTerm!,
        );
    state = AsyncData(ItemState(items: resp.data.items));
  }
}

final searchArtistsProvider = StateNotifierProvider<SearchArtistsNotifier, AsyncData<ItemState>>((ref) {
  return SearchArtistsNotifier(ref, ref.read(searchProvider), AsyncData<ItemState>(ItemState()));
});
