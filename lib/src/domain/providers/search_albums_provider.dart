import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';

class SearchAlbumsNotifier extends AutoDisposeAsyncNotifier<ItemsPage> {
  late JellyfinApi _api;
  var _searchTerm = '';

  @override
  FutureOr<ItemsPage> build() async {
    _api = ref.watch(jellyfinApiProvider);

    final searchQuery = ref.watch(searchProvider)?.trim();

    if (searchQuery == _searchTerm) {
      return state.valueOrNull ?? const ItemsPage();
    }

    _searchTerm = searchQuery ?? '';
    if (_searchTerm.isEmpty) return const ItemsPage();

    final resp = await _api.searchAlbums(
      userId: ref.read(currentUserProvider)!.userId,
      libraryId: ref.read(currentLibraryProvider).valueOrNull?.id,
      searchTerm: _searchTerm,
    );

    return ItemsPage(items: resp.data.items);
  }
}

final searchAlbumProvider =
    AutoDisposeAsyncNotifierProvider<SearchAlbumsNotifier, ItemsPage>(
      SearchAlbumsNotifier.new,
    );
