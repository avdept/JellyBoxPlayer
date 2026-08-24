import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/presentation/pages/artist_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MediaServerClient mockMediaServerClient;
  late User mockUser;

  final faker = Faker.instance;
  final mockBaseUrl = faker.internet.url();
  final mockArtist = LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.name.fullName(),
    kind: ItemKind.artist,
    albumArtist: faker.name.fullName(),
    images: ImageRefs(primary: faker.datatype.uuid()),
  );
  final mockAlbums = LibraryPage(
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
    totalRecordCount: faker.datatype.number(),
  );
  final mockAppearsOn = LibraryPage(
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
    totalRecordCount: faker.datatype.number(),
  );
  final mockUserId = faker.datatype.uuid();

  Widget getWidgetUT({required LibraryItem artist}) => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        mediaServerClientProvider.overrideWith((_) => mockMediaServerClient),
        baseUrlProvider.overrideWith((_) => mockBaseUrl),
        currentUserProvider.overrideWith((_) => mockUser),
      ],
    ),
    home: ArtistPage(artist: artist),
  );

  Future<LibraryPage> mockGetAlbums({
    String? contributingArtistIds,
    List<String>? artistIds,
  }) {
    return mockMediaServerClient.getAlbums(
      userId: mockUserId,
      libraryId: any(named: 'libraryId'),
      startIndex: any(named: 'startIndex'),
      limit: any(named: 'limit'),
      sortBy: any(named: 'sortBy'),
      contributingArtistIds:
          contributingArtistIds ?? any(named: 'contributingArtistIds'),
      sortOrder: any(named: 'sortOrder'),
      artistIds: artistIds ?? any(named: 'artistIds'),
    );
  }

  setUpAll(() {
    registerFallbackValue(ImageKind.primary);
    registerFallbackValue(mockArtist);
  });

  setUp(() {
    mockMediaServerClient = MockMediaServerClient();
    mockUser = MockUser();
    when(
      () => mockMediaServerClient.imageUri(
        any(),
        kind: any(named: 'kind'),
        size: any(named: 'size'),
      ),
    ).thenReturn(Uri.parse('https://example.com/image.jpg'));
    when(
      () => mockGetAlbums(artistIds: [mockArtist.id]),
    ).thenAnswer((_) async => mockAlbums);
    when(
      () => mockGetAlbums(contributingArtistIds: mockArtist.id),
    ).thenAnswer((_) async => mockAppearsOn);
    when(() => mockUser.userId).thenReturn(mockUserId);
  });

  group('ArtistPage', () {
    testWidgets(
      '- displays artist details',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(artist: mockArtist));
        await widgetTester.pump(Duration.zero);
        expect(find.text(mockArtist.name), findsAtLeastNWidgets(1));
        expect(
          find.text(
            mockArtist.overview ?? 'This artist does not have any information.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '- displays list of albums',
      (widgetTester) async {
        when(
          () => mockGetAlbums(contributingArtistIds: mockArtist.id),
        ).thenAnswer((_) async => mockAppearsOn.copyWith(items: const []));
        await widgetTester.pumpWidget(getWidgetUT(artist: mockArtist));
        await widgetTester.pump(Duration.zero);
        final albumUT = mockAlbums.items.first;
        final albumFinder = find.byType(AlbumView);
        expect(albumFinder, findsWidgets);
        expect(
          find.descendant(of: albumFinder, matching: find.text(albumUT.name)),
          findsOneWidget,
        );
        expect(find.text('Albums'), findsOneWidget);
        expect(find.text('Appears On'), findsNothing);
      },
    );

    testWidgets(
      '- displays list of appears on',
      (widgetTester) async {
        when(
          () => mockGetAlbums(artistIds: [mockArtist.id]),
        ).thenAnswer((_) async => mockAlbums.copyWith(items: const []));
        await widgetTester.pumpWidget(getWidgetUT(artist: mockArtist));
        await widgetTester.pump(Duration.zero);
        final albumUT = mockAppearsOn.items.first;
        final albumFinder = find.byType(AlbumView);
        expect(albumFinder, findsWidgets);
        expect(
          find.descendant(of: albumFinder, matching: find.text(albumUT.name)),
          findsOneWidget,
        );
        expect(find.text('Appears On'), findsOneWidget);
        expect(find.text('Albums'), findsNothing);
      },
    );
  });
}
