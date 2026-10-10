import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/letter_index.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/item_list_providers.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class MockCurrentLibraryNotifier extends AutoDisposeAsyncNotifier<LibraryItem?>
    with Mock
    implements CurrentLibraryNotifier {}

void main() {
  late MockMediaServerClient mockApi;

  setUpAll(() {
    registerFallbackValue(const LibraryQuery());
    registerFallbackValue(ItemKind.album);
  });

  ProviderContainer containerWith({required bool isOffline}) {
    final library = MockCurrentLibraryNotifier();
    when(library.build).thenReturn(null);
    final container = createProviderContainer(
      overrides: [
        mediaServerClientProvider.overrideWithValue(mockApi),
        currentUserProvider.overrideWith(
          (_) => const User(userId: 'user-1', token: 'token'),
        ),
        isOfflineProvider.overrideWithValue(isOffline),
        currentLibraryProvider.overrideWith(() => library),
        serverCapabilitiesProvider.overrideWithValue(
          const MediaServerCapabilities(
            artistScopes: {ArtistScope.allArtists},
          ),
        ),
        artistBrowseScopeProvider.overrideWithValue(ArtistScope.allArtists),
      ],
    );
    if (!isOffline) {
      container.listen(itemListProvider(ItemList.albums), (_, _) {});
    }
    return container;
  }

  List<LibraryItem> albums(int start, int count) => [
    for (var i = start; i < start + count; i++)
      LibraryItem(id: 'album-$i', name: 'Album $i', kind: ItemKind.album),
  ];

  final queries = <LibraryQuery>[];

  void serveAlbums({required int total, Duration delay = Duration.zero}) {
    when(() => mockApi.getAlbums(any())).thenAnswer((invocation) async {
      final query = invocation.positionalArguments.first as LibraryQuery;
      queries.add(query);
      await Future<void>.delayed(delay);
      final count = (total - query.startIndex).clamp(0, query.limit);
      return LibraryPage(
        items: albums(query.startIndex, count),
        totalRecordCount: total,
      );
    });
  }

  setUp(() {
    mockApi = MockMediaServerClient();
    queries.clear();
  });

  group('itemListProvider', () {
    test('- fails fast offline instead of waiting out the request', () async {
      final container = containerWith(isOffline: true);

      await expectLater(
        container.read(itemListProvider(ItemList.albums).future),
        throwsA(isA<OfflineException>()),
      );
      verifyZeroInteractions(mockApi);
    });

    test('- loadMore is a no-op while there is no page loaded', () async {
      final container = containerWith(isOffline: true);
      final notifier = container.read(
        itemListProvider(ItemList.albums).notifier,
      );

      await expectLater(
        container.read(itemListProvider(ItemList.albums).future),
        throwsA(isA<OfflineException>()),
      );
      await notifier.loadMore();

      verifyZeroInteractions(mockApi);
    });

    test('- the first page sizes the list from the server total', () async {
      serveAlbums(total: 250);
      final container = containerWith(isOffline: false);

      final page = await container.read(
        itemListProvider(ItemList.albums).future,
      );

      expect(page.length, 250);
      expect(page.itemAt(99)?.id, 'album-99');
      expect(page.itemAt(100), isNull);
      expect(queries.single.limit, ItemListNotifier.pageSize);
    });

    test('- artists are scoped to the selected library', () async {
      when(() => mockApi.getArtists(any())).thenAnswer(
        (_) async => const LibraryPage(),
      );
      final library = MockCurrentLibraryNotifier();
      when(library.build).thenReturn(
        const LibraryItem(id: 'lib-1', name: 'Music', kind: ItemKind.library),
      );
      final container = createProviderContainer(
        overrides: [
          mediaServerClientProvider.overrideWithValue(mockApi),
          currentUserProvider.overrideWith(
            (_) => const User(userId: 'user-1', token: 'token'),
          ),
          isOfflineProvider.overrideWithValue(false),
          currentLibraryProvider.overrideWith(() => library),
          serverCapabilitiesProvider.overrideWithValue(
            const MediaServerCapabilities(
              artistScopes: {ArtistScope.allArtists},
            ),
          ),
          artistBrowseScopeProvider.overrideWithValue(ArtistScope.allArtists),
        ],
      );

      await container.read(itemListProvider(ItemList.artists).future);

      final query =
          verify(() => mockApi.getArtists(captureAny())).captured.single
              as LibraryQuery;
      expect(query.libraryId, 'lib-1');
    });

    test('- loadMore stops once every page is loaded', () async {
      serveAlbums(total: 150);
      final container = containerWith(isOffline: false);
      final provider = itemListProvider(ItemList.albums);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      await notifier.loadMore();
      await notifier.loadMore();

      expect(queries.map((q) => q.startIndex), [0, 100]);
      expect(container.read(provider).requireValue.nextPage, isNull);
    });

    test('- a page in flight is not requested twice', () async {
      serveAlbums(total: 1000, delay: const Duration(milliseconds: 20));
      final container = containerWith(isOffline: false);
      final provider = itemListProvider(ItemList.albums);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      await Future.wait([notifier.ensurePage(4), notifier.ensurePage(4)]);

      expect(queries.map((q) => q.startIndex), [0, 400]);
      expect(
        container.read(provider).requireValue.itemAt(450)?.id,
        'album-450',
      );
    });

    test('- touched pages load only around the last touched page', () async {
      serveAlbums(total: 5000);
      final container = containerWith(isOffline: false);
      final provider = itemListProvider(ItemList.albums);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier)
        ..touchPage(5)
        ..touchPage(6)
        ..touchPage(30)
        ..touchPage(31);

      await Future<void>.delayed(
        ItemListNotifier.pageRequestDelay + const Duration(milliseconds: 20),
      );

      expect(queries.map((q) => q.startIndex), [0, 3000, 3100]);
      expect(notifier.state.requireValue.hasPage(5), isFalse);
    });

    test('- keeps a bounded window of pages around the focus', () async {
      serveAlbums(total: 10000);
      final container = containerWith(isOffline: false);
      final provider = itemListProvider(ItemList.albums);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      for (var page = 1; page <= ItemListNotifier.retainedPages + 5; page++) {
        notifier.touchPage(page);
        await notifier.ensurePage(page);
      }

      final loaded = container.read(provider).requireValue;
      expect(loaded.pages.length, ItemListNotifier.retainedPages);
      expect(loaded.hasPage(0), isFalse);
      expect(loaded.hasPage(ItemListNotifier.retainedPages + 5), isTrue);
      expect(loaded.length, 10000);
    });

    test(
      '- indexOfLetter adopts the backend total and loads the page',
      () async {
        serveAlbums(total: 300);
        when(
          () => mockApi.letterOffset(any(), any(), any()),
        ).thenAnswer((_) async => const LetterOffset(250, total: 300));
        final container = containerWith(isOffline: false);
        container
            .read(filterProvider.notifier)
            .filter(field: EntityFilter.sortName, desc: false);
        final provider = itemListProvider(ItemList.albums);
        await container.read(provider.future);
        final notifier = container.read(provider.notifier);

        final index = await notifier.indexOfLetter('T');

        expect(index, 250);
        final loaded = container.read(provider).requireValue;
        expect(loaded.totalCount, 300);
        expect(loaded.itemAt(250)?.id, 'album-250');
        final letterQuery =
            verify(
                  () => mockApi.letterOffset(ItemKind.album, captureAny(), 'T'),
                ).captured.single
                as LibraryQuery;
        expect(letterQuery.sort, ItemSort.name);
        expect(letterQuery.direction, SortDirection.ascending);
      },
    );

    test('- indexOfLetter asks the backend once per letter', () async {
      serveAlbums(total: 300);
      when(
        () => mockApi.letterOffset(any(), any(), any()),
      ).thenAnswer((_) async => const LetterOffset(10));
      final container = containerWith(isOffline: false);
      container
          .read(filterProvider.notifier)
          .filter(field: EntityFilter.sortName, desc: false);
      final provider = itemListProvider(ItemList.albums);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      await notifier.indexOfLetter('B');
      await notifier.indexOfLetter('B');
      expect(await notifier.supportsLetterIndex(), isTrue);

      verify(() => mockApi.letterOffset(any(), any(), 'B')).called(1);
    });

    test('- indexOfLetter is unavailable unless sorted by name', () async {
      serveAlbums(total: 300);
      final container = containerWith(isOffline: false);
      final provider = itemListProvider(ItemList.albums);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      expect(await notifier.indexOfLetter('B'), isNull);
      expect(await notifier.supportsLetterIndex(), isFalse);
      verifyNever(() => mockApi.letterOffset(any(), any(), any()));
    });

    test('- updateItem replaces the item on whichever page holds it', () async {
      serveAlbums(total: 250);
      final container = containerWith(isOffline: false);
      final provider = itemListProvider(ItemList.albums);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);
      await notifier.ensurePage(2);

      notifier.updateItem(
        LibraryItem(id: 'album-210', name: 'Renamed', kind: ItemKind.album),
      );

      expect(
        container.read(provider).requireValue.itemAt(210)?.name,
        'Renamed',
      );
    });
  });
}
