import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/letter_index.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/artist_scope_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class ItemListNotifier
    extends AutoDisposeFamilyAsyncNotifier<PagedItems, ItemList> {
  static const pageSize = 100;
  static const retainedPages = 30;
  static const pageRequestDelay = Duration(milliseconds: 120);

  late MediaServerClient _api;
  late Filter _filterState;
  late ArtistScope _artistScope;
  String? _libraryId;
  int _generation = 0;
  int _focusPage = 0;
  final _inFlight = <int>{};
  final _requested = <int>{};
  Timer? _requestTimer;
  final _letterOffsets = <String, Future<LetterOffset?>>{};

  SortDirection get _direction =>
      sortDirectionOf(descending: _filterState.desc);

  ItemKind get _kind => switch (arg) {
    ItemList.albums => ItemKind.album,
    ItemList.artists => ItemKind.artist,
    ItemList.genres => ItemKind.genre,
    ItemList.playlists => ItemKind.playlist,
    ItemList.songs => ItemKind.song,
  };

  @override
  FutureOr<PagedItems> build(ItemList arg) async {
    _generation++;
    _focusPage = 0;
    _inFlight.clear();
    _requested.clear();
    _requestTimer?.cancel();
    _requestTimer = null;
    _letterOffsets.clear();
    ref.onDispose(() => _requestTimer?.cancel());
    if (ref.watch(isOfflineProvider)) throw const OfflineException();
    _api = ref.watch(mediaServerClientProvider);
    _filterState = ref.watch(filterProvider);
    _artistScope = ref.watch(effectiveArtistScopeProvider);
    _libraryId = ref.watch(currentLibraryProvider).valueOrNull?.id;
    final first = await _fetch(_queryAt(0));
    return _applyPage(
      const PagedItems(pageSize: pageSize),
      page: 0,
      response: first,
    );
  }

  LibraryQuery _queryAt(int startIndex) => switch (arg) {
    ItemList.albums || ItemList.genres || ItemList.songs => LibraryQuery(
      libraryId: _libraryId,
      sort: _filterState.orderBy.itemSort,
      direction: _direction,
      startIndex: startIndex,
      limit: pageSize,
    ),
    ItemList.artists => LibraryQuery(
      sort: _filterState.orderBy.itemSort,
      direction: _direction,
      startIndex: startIndex,
      limit: pageSize,
      artistScope: _artistScope,
    ),
    ItemList.playlists => LibraryQuery(
      sort: _filterState.orderBy.itemSort,
      direction: _direction,
      startIndex: startIndex,
      limit: pageSize,
    ),
  };

  Future<LibraryPage> _fetch(LibraryQuery query) => switch (arg) {
    ItemList.albums => _api.getAlbums(query),
    ItemList.artists => _api.getArtists(query),
    ItemList.genres => _api.getGenres(query),
    ItemList.playlists => _api.getPlaylists(query),
    ItemList.songs => _api.getAllSongs(query),
  };

  PagedItems _applyPage(
    PagedItems current, {
    required int page,
    required LibraryPage response,
  }) => current
      .withPage(
        page,
        response.items,
        isLastPage: response.items.length < pageSize,
        totalCount: response.totalRecordCount,
      )
      .keepPagesAround(_focusPage, keep: retainedPages);

  Future<void> ensurePage(int page) async {
    final current = state.valueOrNull;
    if (current == null ||
        page < 0 ||
        current.hasPage(page) ||
        !_inFlight.add(page)) {
      return;
    }
    final generation = _generation;
    try {
      final response = await _fetch(_queryAt(page * pageSize));
      if (generation != _generation) return;
      final latest = state.valueOrNull ?? current;
      state = AsyncData(_applyPage(latest, page: page, response: response));
    } on Object catch (error, stackTrace) {
      if (generation != _generation) return;
      state = AsyncError<PagedItems>(error, stackTrace).copyWithPrevious(state);
    } finally {
      if (generation == _generation) _inFlight.remove(page);
    }
  }

  void touchPage(int page) {
    _focusPage = page;
    final current = state.valueOrNull;
    if (current == null || current.hasPage(page) || _inFlight.contains(page)) {
      return;
    }
    _requested.add(page);
    _requestTimer ??= Timer(pageRequestDelay, _flushRequests);
  }

  void _flushRequests() {
    _requestTimer = null;
    final pages = _requested.where((page) => (page - _focusPage).abs() <= 1);
    for (final page in pages.toList()) {
      unawaited(ensurePage(page));
    }
    _requested.clear();
  }

  Future<void> loadMore() async {
    final page = state.valueOrNull?.nextPage;
    if (page == null) return;
    await ensurePage(page);
  }

  Future<LetterOffset?> _letterOffset(String letter) {
    if (_filterState.orderBy != EntityFilter.sortName) return Future.value();
    return _letterOffsets[letter] ??= _api.letterOffset(
      _kind,
      _queryAt(0),
      letter,
    );
  }

  Future<bool> supportsLetterIndex() async =>
      await _letterOffset(letterIndexLetters[1]) != null;

  Future<int?> indexOfLetter(String letter) async {
    final generation = _generation;
    final offset = await _letterOffset(letter);
    final current = state.valueOrNull;
    if (offset == null || current == null || generation != _generation) {
      return null;
    }
    final total = offset.total;
    var next = current;
    if (total != null && total != current.totalCount) {
      next = current.copyWith(totalCount: total);
      state = AsyncData(next);
    }
    if (next.isEmpty) return null;
    final index = offset.index.clamp(0, next.length - 1);
    _focusPage = index ~/ pageSize;
    await ensurePage(_focusPage);
    return generation == _generation ? index : null;
  }

  void updateItem(LibraryItem updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.mapItems((item) => item.id == updated.id ? updated : item),
    );
  }
}

final itemListProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      ItemListNotifier,
      PagedItems,
      ItemList
    >(
      ItemListNotifier.new,
    );

final AutoDisposeFamilyAsyncNotifierProvider<
  ItemListNotifier,
  PagedItems,
  ItemList
>
albumsProvider = itemListProvider(ItemList.albums);

final AutoDisposeFamilyAsyncNotifierProvider<
  ItemListNotifier,
  PagedItems,
  ItemList
>
artistsProvider = itemListProvider(ItemList.artists);

final AutoDisposeFamilyAsyncNotifierProvider<
  ItemListNotifier,
  PagedItems,
  ItemList
>
playlistsProvider = itemListProvider(ItemList.playlists);

final AutoDisposeFamilyAsyncNotifierProvider<
  ItemListNotifier,
  PagedItems,
  ItemList
>
genresProvider = itemListProvider(ItemList.genres);

final AutoDisposeFutureProviderFamily<bool, ItemList>
letterIndexAvailableProvider = FutureProvider.autoDispose
    .family<bool, ItemList>((ref, list) async {
      if (!ref.watch(settingProvider(AppSetting.letterRuler))) return false;
      if (ref.watch(filterProvider).orderBy != EntityFilter.sortName) {
        return false;
      }
      await ref.watch(itemListProvider(list).future);
      return ref.read(itemListProvider(list).notifier).supportsLetterIndex();
    });
