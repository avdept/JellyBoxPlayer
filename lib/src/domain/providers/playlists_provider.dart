import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:string_capitalize/string_capitalize.dart';

class PlaylistsNotifier extends AutoDisposeAsyncNotifier<ItemsPage> {
  late JellyfinApi _api;
  late Filter _filterState;

  @override
  FutureOr<ItemsPage> build() async {
    _api = ref.watch(jellyfinApiProvider);
    _filterState = ref.watch(filterProvider);
    state = const AsyncLoading();
    return _fetchItems();
  }

  Future<ItemsPage> _fetchItems({int startIndex = 0}) async {
    final resp = await _api.getPlaylists(
      userId: ref.read(currentUserProvider)!.userId,
      sortOrder: _filterState.desc ? 'Descending' : 'Ascending',
      sortBy: _filterState.orderBy.name.capitalize(),
      startIndex: startIndex.toString(),
    );
    final value = state.value ?? const ItemsPage();
    return value.copyWith(
      items: [...value.items, ...resp.data.items],
      currentPage: value.currentPage + 1,
    );
  }

  Future<void> loadMore() async {
    state = const AsyncLoading();
    final value = state.requireValue;
    state = await AsyncValue.guard(
      () => _fetchItems(startIndex: value.currentPage * value.totalPerPage),
    );
  }
}

final playlistsProvider =
    AutoDisposeAsyncNotifierProvider<PlaylistsNotifier, ItemsPage>(
      PlaylistsNotifier.new,
    );
