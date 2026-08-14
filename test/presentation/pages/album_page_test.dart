import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/presentation/pages/album_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class MockUser extends Mock implements User {}

class MockDownloadDatabase extends Mock implements DownloadDatabase {}

class MockDownloadManagerNotifier extends AsyncNotifier<List<DownloadedSong>>
    with Mock
    implements DownloadManagerNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MediaServerClient mockMediaServerClient;
  late User mockUser;
  late DownloadManagerNotifier mockDownloadManagerNotifier;
  late DownloadDatabase mockDownloadDatabase;

  final faker = Faker.instance;
  final mockBaseUrl = faker.internet.url();
  final mockAlbum = LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    kind: ItemKind.album,
    productionYear: faker.date.past(DateTime.now()).year,
    albumArtist: faker.name.fullName(),
    images: ImageRefs(primary: faker.datatype.uuid()),
  );
  final mockSongs = LibraryPage(
    items: List.generate(
      10,
      (_) => LibraryItem(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        userData: PlaybackUserData(
          position: Duration(milliseconds: faker.datatype.number(min: 1000)),
          playCount: faker.datatype.number(),
          isFavorite: faker.datatype.boolean(),
          played: faker.datatype.boolean(),
        ),
        kind: ItemKind.song,
        albumArtist: faker.name.fullName(),
        albumName: faker.lorem.sentence(),
        albumId: faker.datatype.uuid(),
      ),
    ),
  );
  final mockSimilarAlbums = LibraryPage(
    items: List.generate(
      3,
      (index) => LibraryItem(
        id: faker.datatype.uuid(),
        name: 'Similar album $index',
        kind: ItemKind.album,
        albumArtist: 'Similar artist $index',
      ),
    ),
  );
  final mockDownloadedSongs = List.generate(
    3,
    (index) => DownloadedSong(
      item: LibraryItem(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        kind: ItemKind.song,
        indexNumber: index + 1,
        albumArtist: faker.name.fullName(),
        albumId: mockAlbum.id,
      ),
      filePath: '/tmp/song$index.flac',
      sizeInBytes: faker.datatype.number(min: 1000),
      downloadDate: DateTime.now(),
    ),
  );
  final mockUserId = faker.datatype.uuid();
  const keys = AlbumPageKeys(
    downloadButton: Key('downloadButton'),
    deleteButton: Key('deleteButton'),
    confirmationDialog: Key('confirmationDialog'),
  );

  Widget getWidgetUT({
    required LibraryItem album,
    bool isAlbumDownloaded = false,
    bool isOffline = false,
  }) {
    return createTestApp(
      providerContainer: createProviderContainer(
        overrides: [
          mediaServerClientProvider.overrideWith((_) => mockMediaServerClient),
          baseUrlProvider.overrideWith((_) => mockBaseUrl),
          currentUserProvider.overrideWith((_) => mockUser),
          downloadManagerProvider.overrideWith(
            () => mockDownloadManagerNotifier,
          ),
          downloadDatabaseProvider.overrideWithValue(mockDownloadDatabase),
          isAlbumDownloadedProvider.overrideWith((_, _) => isAlbumDownloaded),
          isOfflineProvider.overrideWithValue(isOffline),
        ],
      ),
      home: AlbumPage(album: album, testKeys: keys),
    );
  }

  Future<LibraryPage> mockGetSongs({String? albumId}) {
    return mockMediaServerClient.getSongs(
      userId: mockUserId,
      albumId: albumId ?? any(named: 'albumId'),
    );
  }

  Future<LibraryPage> mockGetSimilarAlbums({String? albumId}) {
    return mockMediaServerClient.getSimilarAlbums(
      albumId: albumId ?? any(named: 'albumId'),
      userId: mockUserId,
      limit: any(named: 'limit'),
    );
  }

  final suggestionsHeader = find.text('You may also like');

  Future<void> scrollToSuggestions(WidgetTester tester) => tester
      .scrollUntilVisible(
        suggestionsHeader,
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );

  Future<void> scrollToEnd(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
  }

  setUpAll(() {
    registerFallbackValue(mockAlbum);
    registerFallbackValue(mockSongs);
    registerFallbackValue(ImageKind.primary);
    deviceId = faker.datatype.uuid();
  });

  setUp(() {
    mockMediaServerClient = MockMediaServerClient();
    mockUser = MockUser();
    mockDownloadManagerNotifier = MockDownloadManagerNotifier();
    mockDownloadDatabase = MockDownloadDatabase();
    when(
      () => mockMediaServerClient.imageUrl(
        id: any(named: 'id'),
        tagId: any(named: 'tagId'),
        kind: any(named: 'kind'),
        size: any(named: 'size'),
      ),
    ).thenReturn('https://example.com/image.jpg');
    when(
      () => mockDownloadDatabase.getDownloadedSongs(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockGetSongs(albumId: mockAlbum.id),
    ).thenAnswer((_) async => mockSongs);
    when(
      () => mockGetSimilarAlbums(albumId: mockAlbum.id),
    ).thenAnswer((_) async => const LibraryPage(items: []));
    when(() => mockUser.userId).thenReturn(mockUserId);
  });

  group('AlbumPage', () {
    testWidgets(
      '- displays album details',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(album: mockAlbum));
        await widgetTester.pump(Duration.zero);
        expect(find.text(mockAlbum.name), findsAtLeastNWidgets(1));
        expect(find.text(mockAlbum.albumArtist!), findsOneWidget);
      },
    );

    testWidgets(
      '- displays list of songs',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(album: mockAlbum));
        await widgetTester.pump(Duration.zero);
        final songUT = mockSongs.items.first;
        final songFinder = find.byType(PlayerSongView);
        expect(songFinder, findsWidgets);
        expect(
          find.descendant(
            of: songFinder,
            matching: find.text(songUT.name),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: songFinder,
            matching: find.text(songUT.albumArtist ?? ''),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "- displays download button when album isn't downloaded",
      (widgetTester) async {
        when(
          () => mockDownloadManagerNotifier.downloadAlbum(any(), any()),
        ).thenAnswer((_) async {});
        await widgetTester.pumpWidget(getWidgetUT(album: mockAlbum));
        await widgetTester.pump(Duration.zero);
        final downloadButtonFinder = find.byKey(keys.downloadButton);
        expect(downloadButtonFinder, findsOneWidget);
        expect(find.byKey(keys.deleteButton), findsNothing);
        // Should call downloadAlbum when pressed
        await widgetTester.tap(downloadButtonFinder);
        await widgetTester.pumpAndSettle();
        verify(
          () => mockDownloadManagerNotifier.downloadAlbum(
            mockAlbum,
            mockSongs.items,
          ),
        ).called(1);
      },
    );

    testWidgets(
      '- displays delete button when album is downloaded',
      (widgetTester) async {
        when(
          () => mockDownloadManagerNotifier.deleteAlbum(any()),
        ).thenAnswer((_) async {});
        await widgetTester.pumpWidget(
          getWidgetUT(album: mockAlbum, isAlbumDownloaded: true),
        );
        await widgetTester.pump(Duration.zero);
        final deleteButtonFinder = find.byKey(keys.deleteButton);
        expect(deleteButtonFinder, findsOneWidget);
        expect(find.byKey(keys.downloadButton), findsNothing);
        // Should show confirmation dialog
        final confirmationDialogFinder = find.byKey(keys.confirmationDialog);
        await widgetTester.tap(deleteButtonFinder);
        await widgetTester.pumpAndSettle();
        expect(confirmationDialogFinder, findsOneWidget);
        // Should call deleteAlbum when accepted
        await widgetTester.tap(
          find.descendant(
            of: confirmationDialogFinder,
            matching: find.widgetWithText(AdaptiveDialogAction, 'Yes'),
          ),
        );
        await widgetTester.pumpAndSettle();
        verify(
          () => mockDownloadManagerNotifier.deleteAlbum(mockAlbum.id),
        ).called(1);
      },
    );

    testWidgets(
      '- offline: lists downloaded songs without calling the server',
      (widgetTester) async {
        when(
          () => mockDownloadDatabase.getDownloadedSongs(mockAlbum.id),
        ).thenAnswer((_) async => mockDownloadedSongs);
        await widgetTester.pumpWidget(
          getWidgetUT(
            album: mockAlbum,
            isAlbumDownloaded: true,
            isOffline: true,
          ),
        );
        await widgetTester.pump(Duration.zero);

        expect(
          find.descendant(
            of: find.byType(PlayerSongView),
            matching: find.text(mockDownloadedSongs.first.item.name),
          ),
          findsOneWidget,
        );
        verifyNever(() => mockGetSongs(albumId: mockAlbum.id));
      },
    );

    testWidgets(
      '- offline: shows an offline notice when nothing is downloaded',
      (widgetTester) async {
        await widgetTester.pumpWidget(
          getWidgetUT(album: mockAlbum, isOffline: true),
        );
        await widgetTester.pump(Duration.zero);

        expect(find.byType(OfflineNotice), findsOneWidget);
        expect(find.byType(PlayerSongView), findsNothing);
        expect(find.byKey(keys.downloadButton), findsNothing);
        verifyNever(() => mockGetSongs(albumId: mockAlbum.id));
      },
    );

    testWidgets(
      '- displays similar albums below the song list',
      (widgetTester) async {
        when(
          () => mockGetSimilarAlbums(albumId: mockAlbum.id),
        ).thenAnswer((_) async => mockSimilarAlbums);
        await widgetTester.pumpWidget(getWidgetUT(album: mockAlbum));
        await widgetTester.pumpAndSettle();
        await scrollToSuggestions(widgetTester);

        expect(suggestionsHeader, findsOneWidget);
        final firstSuggestion = mockSimilarAlbums.items.first;
        expect(
          find.descendant(
            of: find.byType(AlbumView),
            matching: find.text(firstSuggestion.name),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AlbumView),
            matching: find.text(firstSuggestion.albumArtist!),
          ),
          findsOneWidget,
        );
        verify(() => mockGetSimilarAlbums(albumId: mockAlbum.id)).called(1);
      },
    );

    testWidgets(
      '- excludes the current album from the suggestions',
      (widgetTester) async {
        when(() => mockGetSimilarAlbums(albumId: mockAlbum.id)).thenAnswer(
          (_) async =>
              LibraryPage(items: [mockAlbum, ...mockSimilarAlbums.items]),
        );
        await widgetTester.pumpWidget(getWidgetUT(album: mockAlbum));
        await widgetTester.pumpAndSettle();
        await scrollToSuggestions(widgetTester);

        expect(
          find.descendant(
            of: find.byType(AlbumView),
            matching: find.text(mockAlbum.name),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(AlbumView),
            matching: find.text(mockSimilarAlbums.items.first.name),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- hides the suggestions section when the server returns none',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(album: mockAlbum));
        await widgetTester.pumpAndSettle();
        await scrollToEnd(widgetTester);

        expect(suggestionsHeader, findsNothing);
        expect(find.byType(AlbumView), findsNothing);
      },
    );

    testWidgets(
      '- offline: does not request similar albums',
      (widgetTester) async {
        await widgetTester.pumpWidget(
          getWidgetUT(album: mockAlbum, isOffline: true),
        );
        await widgetTester.pumpAndSettle();

        expect(suggestionsHeader, findsNothing);
        verifyNever(() => mockGetSimilarAlbums(albumId: mockAlbum.id));
      },
    );
  });
}
