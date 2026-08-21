import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/generated_playlists_setting_provider.dart';
import 'package:jplayer/src/domain/providers/home_sections_provider.dart';
import 'package:jplayer/src/domain/providers/libraries_provider.dart';
import 'package:jplayer/src/domain/providers/studio_mode_provider.dart';
import 'package:jplayer/src/domain/providers/todays_playlists_provider.dart';
import 'package:jplayer/src/presentation/pages/home_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/dev_tools_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockCurrentLibraryNotifier extends AutoDisposeAsyncNotifier<LibraryItem?>
    with Mock
    implements CurrentLibraryNotifier {}

class MockLibrariesNotifier extends AutoDisposeAsyncNotifier<List<LibraryItem>>
    with Mock
    implements LibrariesNotifier {}

class DisabledSettingNotifier extends BoolPrefNotifier {
  DisabledSettingNotifier() : super(null, key: 'test', defaultValue: true);
}

class FakeTodaysPlaylistsNotifier extends TodaysPlaylistsNotifier {
  FakeTodaysPlaylistsNotifier(this.playlists);

  final List<GeneratedPlaylist> playlists;
  int regenerateCount = 0;

  @override
  Future<List<GeneratedPlaylist>> build() async => playlists;

  @override
  Future<void> regenerate() async => regenerateCount++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurrentLibraryNotifier mockCurrentLibraryNotifier;
  late LibrariesNotifier mockLibrariesNotifier;
  late FakeTodaysPlaylistsNotifier fakeTodaysPlaylists;

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

  List<GeneratedPlaylist> createGenerated(int count) => List.generate(
    count,
    (index) => GeneratedPlaylist(
      item: LibraryItem(
        id: 'generated-$index',
        name: '${faker.lorem.word()} mix',
        kind: ItemKind.playlist,
      ),
      coverSongs: const [],
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
    List<GeneratedPlaylist>? generated,
    bool isOffline = false,
    bool devTools = false,
    bool generatedDisabled = false,
  }) {
    return createTestApp(
      providerContainer: createProviderContainer(
        overrides: [
          isOfflineProvider.overrideWith((_) => isOffline),
          devToolsEnabledProvider.overrideWith((_) => devTools),
          if (generatedDisabled)
            generatedPlaylistsDisabledProvider.overrideWith(
              (_) => DisabledSettingNotifier(),
            ),
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
          todaysPlaylistsProvider.overrideWith(() {
            return fakeTodaysPlaylists = FakeTodaysPlaylistsNotifier(
              generated ?? createGenerated(3),
            );
          }),
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
    List<GeneratedPlaylist>? generated,
    bool isOffline = false,
    bool devTools = false,
    bool generatedDisabled = false,
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
        generated: generated,
        isOffline: isOffline,
        devTools: devTools,
        generatedDisabled: generatedDisabled,
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
      expect(find.text('Made for you'), findsOneWidget);
      expect(find.text('Recently added'), findsOneWidget);
      expect(find.text('Favourites'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Frequently played'), findsOneWidget);
      expect(find.byType(ItemCarousel), findsNWidgets(6));
    });

    testWidgets('- orders the sections with frequently played last', (
      widgetTester,
    ) async {
      await pumpHome(widgetTester);

      final titles = [
        'Recently played',
        'Made for you',
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
          generated: const [],
        );

        expect(find.text('Recently played'), findsNothing);
        expect(find.text('Made for you'), findsNothing);
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

    testWidgets('- rebuilds the mixes from the debug action', (
      widgetTester,
    ) async {
      await pumpHome(widgetTester, devTools: true);

      final button = find.descendant(
        of: find.widgetWithText(ItemCarousel, 'Made for you'),
        matching: find.byIcon(Icons.refresh),
      );
      expect(button, findsOneWidget);
      expect(fakeTodaysPlaylists.regenerateCount, 0);

      await widgetTester.tap(button);
      await widgetTester.pump();

      expect(fakeTodaysPlaylists.regenerateCount, 1);
    });

    testWidgets('- keeps the debug action reachable when no mix qualified', (
      widgetTester,
    ) async {
      await pumpHome(widgetTester, generated: const [], devTools: true);

      expect(find.text('Made for you'), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(ItemCarousel, 'Made for you'),
          matching: find.byIcon(Icons.refresh),
        ),
        findsOneWidget,
      );
    });

    testWidgets('- drops the shelf entirely when the setting disables it', (
      widgetTester,
    ) async {
      await pumpHome(
        widgetTester,
        devTools: true,
        generatedDisabled: true,
      );

      expect(find.text('Made for you'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.text('Recently played'), findsOneWidget);
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
