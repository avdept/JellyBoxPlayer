import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/providers/play_history_database_provider.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/play_history_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/download_badge_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/home_sections_provider.dart';
import 'package:jplayer/src/domain/providers/libraries_provider.dart';
import 'package:jplayer/src/domain/providers/on_repeat_provider.dart';
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

class MockMediaServerClient extends Mock implements MediaServerClient {}

class MockDownloadManager extends Mock implements DownloadManager {}

class MockDownloadDatabase extends Mock implements DownloadDatabase {}

class MockPlayHistoryDatabase extends Mock implements PlayHistoryDatabase {}

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
  late MockMediaServerClient mockClient;
  late MockDownloadManager mockDownloadManager;
  late MockDownloadDatabase mockDownloadDatabase;
  late MockPlayHistoryDatabase mockPlayHistory;

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
    ContentUpdateInterval? updateInterval,
    VoidCallback? onRecentlyAddedFetch,
  }) {
    return createTestApp(
      providerContainer: createProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (_) => const User(userId: 'user-1', token: 't'),
          ),
          isOfflineProvider.overrideWith((_) => isOffline),
          if (updateInterval != null)
            contentUpdateIntervalProvider.overrideWithValue(updateInterval),
          devToolsEnabledProvider.overrideWith((_) => devTools),
          if (generatedDisabled)
            settingProvider(
              AppSetting.generatedPlaylistsDisabled,
            ).overrideWithValue(true),
          favouriteSongsProvider.overrideWith((_) async => const LibraryPage()),
          favouriteAlbumsProvider.overrideWith(
            (_) async => favourites ?? createItems(3, ItemKind.album),
          ),
          favouritePlaylistsProvider.overrideWith((_) async => const []),
          recentlyPlayedAlbumsProvider.overrideWith(
            (_) async => recentlyPlayed ?? createItems(3, ItemKind.album),
          ),
          recentlyAddedAlbumsProvider.overrideWith((_) async {
            onRecentlyAddedFetch?.call();
            return recentlyAdded ?? createItems(3, ItemKind.album);
          }),
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
          mediaServerClientProvider.overrideWith((_) => mockClient),
          downloadManagerProvider.overrideWithValue(mockDownloadManager),
          downloadDatabaseProvider.overrideWithValue(mockDownloadDatabase),
          playHistoryDatabaseProvider.overrideWithValue(mockPlayHistory),
          downloadedCollectionsProvider.overrideWith(
            (_) async => (albums: <String>{}, playlists: <String>{}),
          ),
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
    ContentUpdateInterval? updateInterval,
    VoidCallback? onRecentlyAddedFetch,
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
        updateInterval: updateInterval,
        onRecentlyAddedFetch: onRecentlyAddedFetch,
      ),
    );
    await widgetTester.pump(Duration.zero);
    await widgetTester.pump(Duration.zero);
  }

  setUpAll(() {
    registerFallbackValue(const LibraryQuery());
    registerFallbackValue(likedSongsPlaylistFor('user-1'));
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockCurrentLibraryNotifier = MockCurrentLibraryNotifier();
    mockLibrariesNotifier = MockLibrariesNotifier();
    mockClient = MockMediaServerClient();
    mockDownloadManager = MockDownloadManager();
    mockDownloadDatabase = MockDownloadDatabase();
    mockPlayHistory = MockPlayHistoryDatabase();
    when(
      () => mockPlayHistory.trackedSongCount(window: any(named: 'window')),
    ).thenAnswer((_) async => onRepeatMinimumSongs);
    when(mockCurrentLibraryNotifier.build).thenAnswer((_) async => mockLibrary);
    when(mockLibrariesNotifier.build).thenAnswer((_) async => [mockLibrary]);
    when(
      () => mockClient.capabilities,
    ).thenReturn(const MediaServerCapabilities());
    when(
      mockClient.resolveCapabilities,
    ).thenAnswer((_) async => const MediaServerCapabilities());
  });

  Future<void> openCardMenu(WidgetTester widgetTester, String name) async {
    await widgetTester.longPress(
      find.ancestor(of: find.text(name), matching: find.byType(AlbumView)),
    );
    await widgetTester.pumpAndSettle();
  }

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

    testWidgets('- refetches recently added on the update interval', (
      widgetTester,
    ) async {
      var fetches = 0;
      await pumpHome(
        widgetTester,
        updateInterval: ContentUpdateInterval.min1,
        onRecentlyAddedFetch: () => fetches++,
      );
      expect(fetches, 1);

      await widgetTester.pump(const Duration(minutes: 1));
      await widgetTester.pump(Duration.zero);
      expect(fetches, 2);

      await widgetTester.pump(const Duration(minutes: 1));
      await widgetTester.pump(Duration.zero);
      expect(fetches, 3);
    });

    testWidgets('- never refetches when updates are off', (
      widgetTester,
    ) async {
      var fetches = 0;
      await pumpHome(
        widgetTester,
        updateInterval: ContentUpdateInterval.never,
        onRecentlyAddedFetch: () => fetches++,
      );

      await widgetTester.pump(const Duration(hours: 1));
      await widgetTester.pump(Duration.zero);
      expect(fetches, 1);
    });

    testWidgets('- orders the sections with frequently played last', (
      widgetTester,
    ) async {
      await pumpHome(widgetTester);

      final titles = [
        'Recently added',
        'Made for you',
        'Recently played',
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
        expect(find.text('On repeat'), findsOneWidget);
        expect(find.byType(AlbumView), findsNWidgets(2));
      },
    );

    testWidgets('- hides On repeat until enough tracked songs exist', (
      widgetTester,
    ) async {
      when(
        () => mockPlayHistory.trackedSongCount(window: any(named: 'window')),
      ).thenAnswer((_) async => onRepeatMinimumSongs - 1);

      await pumpHome(widgetTester, playlists: const []);

      expect(find.text('Liked songs'), findsOneWidget);
      expect(find.text('On repeat'), findsNothing);
    });

    testWidgets('- lists Liked songs and On repeat ahead of the real '
        'playlists', (widgetTester) async {
      final realPlaylists = createItems(2, ItemKind.playlist);
      await pumpHome(widgetTester, playlists: realPlaylists);
      widgetTester.view.physicalSize = const Size(1600, 2000);
      await widgetTester.pump();
      await widgetTester.pump(const Duration(seconds: 1));

      expect(find.text('Liked songs'), findsOneWidget);
      final liked = widgetTester.getTopLeft(find.text('Liked songs')).dx;
      final onRepeat = widgetTester.getTopLeft(find.text('On repeat')).dx;
      final real = widgetTester
          .getTopLeft(find.text(realPlaylists.first.name))
          .dx;
      expect(liked, lessThan(onRepeat));
      expect(onRepeat, lessThan(real));
    });

    testWidgets('- offers play and download on the Liked songs card', (
      widgetTester,
    ) async {
      await pumpHome(widgetTester);
      await openCardMenu(widgetTester, 'Liked songs');

      expect(find.text('Play playlist'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Add to favourites'), findsNothing);
    });

    testWidgets('- downloads Liked songs from the card menu', (
      widgetTester,
    ) async {
      final liked = likedSongsPlaylistFor('user-1');
      final songs = createItems(2, ItemKind.song);
      when(
        () => mockClient.getAllSongs(any()),
      ).thenAnswer((_) async => LibraryPage(items: songs));
      when(
        () => mockDownloadDatabase.isPlaylistDownloaded(liked.id),
      ).thenAnswer((_) async => false);
      when(
        () => mockDownloadManager.downloadPlaylist(any(), any()),
      ).thenAnswer((_) async {});
      await pumpHome(widgetTester);
      await openCardMenu(widgetTester, 'Liked songs');

      await widgetTester.tap(find.text('Download'));
      await widgetTester.pumpAndSettle();

      verify(
        () => mockDownloadManager.downloadPlaylist(liked, songs),
      ).called(1);
      verifyNever(() => mockClient.getPlaylistSongs(any()));
    });

    testWidgets('- offers play and download on a Made for you card', (
      widgetTester,
    ) async {
      final generated = createGenerated(2);
      await pumpHome(widgetTester, generated: generated);
      await openCardMenu(widgetTester, generated.first.item.name);

      expect(find.text('Play playlist'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
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

      final titleChevron = find.descendant(
        of: find.byType(ClickableWidget),
        matching: find.byIcon(Icons.chevron_right),
      );
      expect(titleChevron, findsOneWidget);
      expect(
        find.ancestor(
          of: titleChevron,
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
