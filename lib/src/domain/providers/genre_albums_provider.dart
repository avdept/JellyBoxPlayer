import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class GenreAlbumsNotifier
    extends AutoDisposeFamilyAsyncNotifier<ItemsPage, String> {
  late MediaServerClient _client;
  String? _libraryId;

  @override
  FutureOr<ItemsPage> build(String arg) async {
    if (ref.watch(isOfflineProvider)) throw const OfflineException();
    _client = ref.watch(mediaServerClientProvider);
    _libraryId = ref.watch(currentLibraryProvider).valueOrNull?.id;
    return _fetchItems(startPage: const ItemsPage());
  }

  Future<ItemsPage> _fetchItems({
    int startIndex = 0,
    ItemsPage startPage = const ItemsPage(),
  }) async {
    final resp = await _client.getAlbums(
      userId: ref.read(currentUserProvider)!.userId,
      libraryId: _libraryId,
      genreIds: [arg],
      sortBy: 'SortName',
      sortOrder: 'Ascending',
      startIndex: startIndex.toString(),
    );
    return startPage.copyWith(
      items: [...startPage.items, ...resp.items],
      currentPage: startPage.currentPage + 1,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = await AsyncValue.guard(
      () => _fetchItems(
        startIndex: current.currentPage * current.totalPerPage,
        startPage: current,
      ),
    );
  }
}

final genreAlbumsProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      GenreAlbumsNotifier,
      ItemsPage,
      String
    >(
      GenreAlbumsNotifier.new,
    );
