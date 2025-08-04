import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/album_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockJellyfinApi extends Mock implements JellyfinApi {}

class MockHttpResponse<T> extends Mock implements HttpResponse<T> {}

class MockUser extends Mock implements User {}

class MockDownloadManagerNotifier extends AsyncNotifier<List<DownloadedSongDTO>>
    with Mock
    implements DownloadManagerNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JellyfinApi mockJellyfinApi;
  late HttpResponse<ItemsWrapper> mockSongsResponse;
  late User mockUser;
  late DownloadManagerNotifier mockDownloadManagerNotifier;

  final faker = Faker.instance;
  final mockBaseUrl = faker.internet.url();
  final mockAlbum = ItemDTO(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    type: 'Album',
    runTimeTicks: faker.datatype.number(min: 10000),
    productionYear: faker.date.past(DateTime.now()).year,
    albumArtist: faker.name.fullName(),
    imageTags: {'Primary': faker.datatype.uuid()},
  );
  final mockSongs = ItemsWrapper(
    items: List.generate(
      10,
      (_) => ItemDTO(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        runTimeTicks: faker.datatype.number(min: 10000),
        userData: UserData(
          playbackPositionTicks: faker.datatype.number(min: 1000),
          playCount: faker.datatype.number(),
          isFavorite: faker.datatype.boolean(),
          played: faker.datatype.boolean(),
        ),
        type: 'Song',
        albumArtist: faker.name.fullName(),
        albumName: faker.lorem.sentence(),
        albumId: faker.datatype.uuid(),
      ),
    ),
  );
  final mockUserId = faker.datatype.uuid();
  const keys = AlbumPageKeys(
    downloadButton: Key('downloadButton'),
    deleteButton: Key('deleteButton'),
    confirmationDialog: Key('confirmationDialog'),
  );

  Widget getWidgetUT({
    required ItemDTO album,
    bool isAlbumDownloaded = false,
  }) {
    return createTestApp(
      providerContainer: createProviderContainer(
        overrides: [
          jellyfinApiProvider.overrideWith((_) => mockJellyfinApi),
          baseUrlProvider.overrideWith((_) => mockBaseUrl),
          currentUserProvider.overrideWith((_) => mockUser),
          downloadManagerProvider.overrideWith(
            () => mockDownloadManagerNotifier,
          ),
          isAlbumDownloadedProvider.overrideWith((_, _) => isAlbumDownloaded),
        ],
      ),
      home: AlbumPage(album: album, testKeys: keys),
    );
  }

  Future<HttpResponse<ItemsWrapper>> mockGetSongs({
    String? albumId,
  }) {
    return mockJellyfinApi.getSongs(
      userId: mockUserId,
      albumId: albumId ?? any(named: 'albumId'),
      includeType: any(named: 'includeType'),
    );
  }

  setUpAll(() {
    registerFallbackValue(mockAlbum);
    registerFallbackValue(mockSongs);
    deviceId = faker.datatype.uuid();
  });

  setUp(() {
    mockJellyfinApi = MockJellyfinApi();
    mockSongsResponse = MockHttpResponse();
    mockUser = MockUser();
    mockDownloadManagerNotifier = MockDownloadManagerNotifier();
    when(
      () => mockGetSongs(albumId: mockAlbum.id),
    ).thenAnswer((_) async => mockSongsResponse);
    when(() => mockSongsResponse.data).thenReturn(mockSongs);
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
  });
}
