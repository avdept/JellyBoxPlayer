import 'dart:async';

import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/item_list_providers.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/libraries_provider.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/presentation/pages/browse_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockItemListNotifier
    extends AutoDisposeFamilyAsyncNotifier<ItemsPage, ItemList>
    with Mock
    implements ItemListNotifier {}

class MockCurrentLibraryNotifier extends AutoDisposeAsyncNotifier<LibraryItem?>
    with Mock
    implements CurrentLibraryNotifier {}

class MockLibrariesNotifier extends AutoDisposeAsyncNotifier<List<LibraryItem>>
    with Mock
    implements LibrariesNotifier {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurrentLibraryNotifier mockCurrentLibraryNotifier;
  late LibrariesNotifier mockLibrariesNotifier;
  late User mockUser;

  final faker = Faker.instance;
  final mockAlbums = ItemsPage(
    items: List.generate(
      5,
      (_) => LibraryItem(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        kind: ItemKind.album,
        productionYear: faker.date.past(DateTime.now()).year,
        albumArtist: faker.name.fullName(),
      ),
    ),
  );
  final mockArtists = ItemsPage(
    items: List.generate(
      5,
      (_) => LibraryItem(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        kind: ItemKind.artist,
        productionYear: faker.date.past(DateTime.now()).year,
        albumArtist: faker.name.fullName(),
      ),
    ),
  );
  final mockPlaylists = ItemsPage(
    items: List.generate(
      5,
      (_) => LibraryItem(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        kind: ItemKind.playlist,
        productionYear: faker.date.past(DateTime.now()).year,
        albumArtist: faker.name.fullName(),
      ),
    ),
  );
  final mockGenres = ItemsPage(
    items: List.generate(
      5,
      (index) => LibraryItem(
        id: faker.datatype.uuid(),
        name: '${faker.lorem.word()} $index',
        kind: ItemKind.genre,
      ),
    ),
  );
  final mockSongs = ItemsPage(
    items: List.generate(
      5,
      (_) => LibraryItem(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        kind: ItemKind.song,
        albumArtist: faker.name.fullName(),
      ),
    ),
  );
  final mockLibrary = LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    path: faker.internet.url(),
    kind: ItemKind.library,
    collectionType: 'music',
  );

  ItemListNotifier createLoadingItemListMock() {
    final mock = MockItemListNotifier();
    when(() => mock.loadMore()).thenAnswer((_) async {});
    for (final list in ItemList.values) {
      when(
        () => mock.build(list),
      ).thenAnswer((_) => Completer<ItemsPage>().future);
    }
    return mock;
  }

  Widget getLoadingWidgetUT({BrowseLayout? layout}) => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        itemListProvider.overrideWith(createLoadingItemListMock),
        currentLibraryProvider.overrideWith(() => mockCurrentLibraryNotifier),
        librariesProvider.overrideWith(() => mockLibrariesNotifier),
        currentUserProvider.overrideWith((_) => mockUser),
        if (layout != null) browseLayoutProvider.overrideWithValue(layout),
      ],
    ),
    home: const BrowsePage(),
  );

  ItemListNotifier createItemListMock() {
    final mock = MockItemListNotifier();
    when(() => mock.loadMore()).thenAnswer((_) async {});
    when(
      () => mock.build(ItemList.albums),
    ).thenAnswer((_) async => mockAlbums);
    when(
      () => mock.build(ItemList.artists),
    ).thenAnswer((_) async => mockArtists);
    when(
      () => mock.build(ItemList.playlists),
    ).thenAnswer((_) async => mockPlaylists);
    when(
      () => mock.build(ItemList.genres),
    ).thenAnswer((_) async => mockGenres);
    when(() => mock.build(ItemList.songs)).thenAnswer((_) async => mockSongs);
    return mock;
  }

  Widget getWidgetUT({BrowseLayout? layout}) => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        itemListProvider.overrideWith(createItemListMock),
        currentLibraryProvider.overrideWith(() => mockCurrentLibraryNotifier),
        librariesProvider.overrideWith(() => mockLibrariesNotifier),
        currentUserProvider.overrideWith((_) => mockUser),
        if (layout != null) browseLayoutProvider.overrideWithValue(layout),
      ],
    ),
    home: const BrowsePage(),
  );

  setUp(() {
    mockCurrentLibraryNotifier = MockCurrentLibraryNotifier();
    mockLibrariesNotifier = MockLibrariesNotifier();
    mockUser = MockUser();
    when(() => mockUser.userId).thenReturn(faker.datatype.uuid());
    when(mockCurrentLibraryNotifier.build).thenAnswer((_) async => mockLibrary);
    when(mockLibrariesNotifier.build).thenAnswer((_) async => [mockLibrary]);
  });

  group('BrowsePage loading', () {
    testWidgets('- shimmers as cards while cards are selected', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(getLoadingWidgetUT());
      await widgetTester.pump(Duration.zero);

      expect(find.byType(AlbumCardsGridShimmer), findsOneWidget);
      expect(find.byType(SongRowsShimmer), findsNothing);
    });

    testWidgets('- shimmers as rows while rows are selected', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(
        getLoadingWidgetUT(layout: BrowseLayout.rows),
      );
      await widgetTester.pump(Duration.zero);

      expect(find.byType(SongRowsShimmer), findsOneWidget);
      expect(find.byType(AlbumCardsGridShimmer), findsNothing);
    });
  });

  group('BrowsePage layout', () {
    testWidgets('- shows cards by default', (widgetTester) async {
      await widgetTester.pumpWidget(getWidgetUT());
      await widgetTester.pump(Duration.zero);

      expect(find.byType(AlbumView), findsWidgets);
      expect(find.byType(ItemRowView), findsNothing);
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
    });

    testWidgets('- shows rows when the setting selects them', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(getWidgetUT(layout: BrowseLayout.rows));
      await widgetTester.pump(Duration.zero);

      expect(find.byType(ItemRowView), findsWidgets);
      expect(find.byType(AlbumView), findsNothing);
      expect(find.byIcon(Icons.view_list), findsOneWidget);
    });

    testWidgets('- hides the toggle on the Songs tab, which is always rows', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(getWidgetUT());
      await widgetTester.pump(Duration.zero);
      expect(find.byIcon(Icons.grid_view), findsOneWidget);

      final songsChip = find.widgetWithText(ActionChip, 'Songs');
      await widgetTester.ensureVisible(songsChip);
      await widgetTester.pumpAndSettle();
      await widgetTester.tap(songsChip);
      await widgetTester.pumpAndSettle();

      expect(find.byType(SongRowView), findsWidgets);
      expect(find.byIcon(Icons.grid_view), findsNothing);
      expect(find.byIcon(Icons.view_list), findsNothing);
      expect(find.byIcon(Icons.sort), findsOneWidget);
    });

    testWidgets('- rows keep the same tap-through as cards', (
      widgetTester,
    ) async {
      await widgetTester.pumpWidget(getWidgetUT(layout: BrowseLayout.rows));
      await widgetTester.pump(Duration.zero);

      final rows = widgetTester
          .widgetList<ItemRowView>(find.byType(ItemRowView))
          .toList();
      expect(rows, isNotEmpty);
      for (final row in rows) {
        expect(row.onTap, isNotNull);
        expect(row.onPlayPressed, isNotNull);
      }
    });
  });

  group('BrowsePage', () {
    testWidgets(
      '- displays list of albums',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        final albumUT = mockAlbums.items.first;
        final albumFinder = find.byType(AlbumView);
        expect(albumFinder, findsWidgets);
        expect(
          find.descendant(of: albumFinder, matching: find.text(albumUT.name)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- displays list of genres when the Genres tab is selected',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await widgetTester.tap(find.widgetWithText(ActionChip, 'Genres'));
        await widgetTester.pumpAndSettle();
        final genreUT = mockGenres.items.first;
        final genreFinder = find.byType(AlbumView);
        expect(genreFinder, findsWidgets);
        expect(
          find.descendant(of: genreFinder, matching: find.text(genreUT.name)),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- reveals a search field with clear button when search is tapped',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        await widgetTester.tap(find.widgetWithIcon(IconButton, JPlayer.search));
        await widgetTester.pumpAndSettle();
        final searchFieldFinder = find.widgetWithIcon(
          TextField,
          JPlayer.search,
        );
        expect(searchFieldFinder, findsOneWidget);
        expect(
          find.descendant(
            of: searchFieldFinder,
            matching: find.widgetWithIcon(IconButton, JPlayer.close),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- displays view toggles',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT());
        await widgetTester.pump(Duration.zero);
        const views = {'Albums', 'Artists', 'Genres', 'Playlists', 'Songs'};
        final chipFinder = find.byType(ActionChip);
        expect(chipFinder, findsNWidgets(views.length));
        for (final label in views) {
          expect(
            find.descendant(of: chipFinder, matching: find.text(label)),
            findsOneWidget,
          );
        }
      },
    );
  });
}
