import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/home_sections_provider.dart';
import 'package:jplayer/src/domain/providers/libraries_provider.dart';
import 'package:jplayer/src/presentation/pages/home_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockCurrentLibraryNotifier extends AutoDisposeAsyncNotifier<LibraryItem?>
    with Mock
    implements CurrentLibraryNotifier {}

class MockLibrariesNotifier extends AutoDisposeAsyncNotifier<List<LibraryItem>>
    with Mock
    implements LibrariesNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurrentLibraryNotifier mockCurrentLibraryNotifier;
  late LibrariesNotifier mockLibrariesNotifier;

  final faker = Faker.instance;

  List<LibraryItem> createItems(int count, ItemKind kind) => List.generate(
    count,
    (_) => LibraryItem(
      id: faker.datatype.uuid(),
      name: faker.lorem.sentence(),
      kind: kind,
      albumArtist: faker.name.fullName(),
    ),
  );

  final mockLibrary = LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.word(),
    kind: ItemKind.library,
    collectionType: 'music',
  );

  Widget getWidgetUT({
    List<LibraryItem>? favourites,
    List<LibraryItem>? recentlyPlayed,
    List<LibraryItem>? recentlyAdded,
    List<LibraryItem>? playlists,
    List<LibraryItem>? frequentlyPlayed,
    bool isOffline = false,
  }) {
    return createTestApp(
      providerContainer: createProviderContainer(
        overrides: [
          isOfflineProvider.overrideWith((_) => isOffline),
          favouriteSongsProvider.overrideWith((_) async => const LibraryPage()),
          favouriteAlbumsProvider.overrideWith(
            (_) async => favourites ?? createItems(3, ItemKind.album),
          ),
          recentlyPlayedAlbumsProvider.overrideWith(
            (_) async => recentlyPlayed ?? createItems(3, ItemKind.album),
          ),
          recentlyAddedAlbumsProvider.overrideWith(
            (_) async => recentlyAdded ?? createItems(3, ItemKind.album),
          ),
          recentlyUpdatedPlaylistsProvider.overrideWith(
            (_) async => playlists ?? createItems(3, ItemKind.playlist),
          ),
          frequentlyPlayedAlbumsProvider.overrideWith(
            (_) async => frequentlyPlayed ?? createItems(3, ItemKind.album),
          ),
          currentLibraryProvider.overrideWith(() => mockCurrentLibraryNotifier),
          librariesProvider.overrideWith(() => mockLibrariesNotifier),
        ],
      ),
      home: const HomePage(),
    );
  }

  Future<void> pumpHome(
    WidgetTester widgetTester, {
    List<LibraryItem>? favourites,
    List<LibraryItem>? recentlyPlayed,
    List<LibraryItem>? recentlyAdded,
    List<LibraryItem>? playlists,
    List<LibraryItem>? frequentlyPlayed,
    bool isOffline = false,
  }) async {
    widgetTester.view.physicalSize = const Size(390, 2000);
    widgetTester.view.devicePixelRatio = 1;
    addTearDown(widgetTester.view.reset);

    await widgetTester.pumpWidget(
      getWidgetUT(
        favourites: favourites,
        recentlyPlayed: recentlyPlayed,
        recentlyAdded: recentlyAdded,
        playlists: playlists,
        frequentlyPlayed: frequentlyPlayed,
        isOffline: isOffline,
      ),
    );
    await widgetTester.pump(Duration.zero);
  }

  setUp(() {
    mockCurrentLibraryNotifier = MockCurrentLibraryNotifier();
    mockLibrariesNotifier = MockLibrariesNotifier();
    when(mockCurrentLibraryNotifier.build).thenAnswer((_) async => mockLibrary);
    when(mockLibrariesNotifier.build).thenAnswer((_) async => [mockLibrary]);
  });

  group('HomePage', () {
    testWidgets('- shows every section that has content', (
      widgetTester,
    ) async {
      await pumpHome(widgetTester);

      expect(find.text('Recently played'), findsOneWidget);
      expect(find.text('Recently added'), findsOneWidget);
      expect(find.text('Favourites'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Frequently played'), findsOneWidget);
      expect(find.byType(ItemCarousel), findsNWidgets(5));
    });

    testWidgets('- orders the sections with frequently played last', (
      widgetTester,
    ) async {
      await pumpHome(widgetTester);

      final titles = [
        'Recently played',
        'Recently added',
        'Favourites',
        'Playlists',
        'Frequently played',
      ].map((title) => widgetTester.getTopLeft(find.text(title)).dy).toList();

      for (var i = 1; i < titles.length; i++) {
        expect(titles[i - 1], lessThan(titles[i]));
      }
    });

    testWidgets('- hides only the sections that came back empty', (
      widgetTester,
    ) async {
      await pumpHome(
        widgetTester,
        recentlyPlayed: const [],
        frequentlyPlayed: const [],
      );

      expect(find.text('Recently played'), findsNothing);
      expect(find.text('Frequently played'), findsNothing);
      expect(find.text('Recently added'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
    });

    testWidgets(
      '- keeps only the Liked songs entry when everything is empty',
      (widgetTester) async {
        await pumpHome(
          widgetTester,
          favourites: const [],
          recentlyPlayed: const [],
          recentlyAdded: const [],
          playlists: const [],
          frequentlyPlayed: const [],
        );

        expect(find.text('Recently played'), findsNothing);
        expect(find.text('Recently added'), findsNothing);
        expect(find.text('Frequently played'), findsNothing);
        expect(find.text('Favourites'), findsNothing);

        expect(find.text('Playlists'), findsOneWidget);
        expect(find.text('Liked songs'), findsOneWidget);
        expect(find.byType(AlbumView), findsOneWidget);
      },
    );

    testWidgets('- lists Liked songs ahead of the real playlists', (
      widgetTester,
    ) async {
      final realPlaylists = createItems(2, ItemKind.playlist);
      await pumpHome(widgetTester, playlists: realPlaylists);

      expect(find.text('Liked songs'), findsOneWidget);
      expect(
        widgetTester.getTopLeft(find.text('Liked songs')).dx,
        lessThan(
          widgetTester.getTopLeft(find.text(realPlaylists.first.name)).dx,
        ),
      );
    });

    testWidgets('- replaces the sections with a notice when offline', (
      widgetTester,
    ) async {
      await pumpHome(widgetTester, isOffline: true);

      expect(find.byType(OfflineNotice), findsOneWidget);
      expect(find.byType(ItemCarousel), findsNothing);
      expect(find.text('Recently added'), findsNothing);
    });

    testWidgets('- gives only the favourites section a chevron', (
      widgetTester,
    ) async {
      await pumpHome(widgetTester);

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.widgetWithText(ItemCarousel, 'Favourites'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('- keeps the library selector in the top bar', (
      widgetTester,
    ) async {
      await pumpHome(widgetTester);

      expect(find.byType(LibrarySelectorButton), findsOneWidget);
      expect(find.text(mockLibrary.name), findsOneWidget);
    });
  });
}
