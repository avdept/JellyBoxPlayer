import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/presentation/pages/artist_page.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart';

import '../../app_wrapper.dart';

class MockJellyfinApi extends Mock implements JellyfinApi {}

class MockHttpResponse<T> extends Mock implements HttpResponse<T> {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JellyfinApi mockJellyfinApi;
  late HttpResponse<AlbumsWrapper> mockAlbumsResponse;
  late HttpResponse<AlbumsWrapper> mockAppearsOnResponse;
  late User mockUser;

  final faker = Faker.instance;
  final mockArtist = ItemDTO(
    id: faker.datatype.uuid(),
    name: faker.name.fullName(),
    serverId: faker.datatype.uuid(),
    type: 'Artist',
    durationInTicks: faker.datatype.number(min: 10000),
    albumArtist: faker.name.fullName(),
    imageTags: {'Primary': faker.datatype.uuid()},
  );
  final mockAlbums = AlbumsWrapper(
    items: List.generate(
      5,
      (_) => ItemDTO(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        serverId: faker.datatype.uuid(),
        type: 'Album',
        durationInTicks: faker.datatype.number(min: 10000),
        productionYear: faker.date.past(DateTime.now()).year,
        albumArtist: faker.name.fullName(),
      ),
    ),
    totalRecordCount: faker.datatype.number(),
  );
  final mockAppearsOn = AlbumsWrapper(
    items: List.generate(
      5,
      (_) => ItemDTO(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        serverId: faker.datatype.uuid(),
        type: 'Album',
        durationInTicks: faker.datatype.number(min: 10000),
        productionYear: faker.date.past(DateTime.now()).year,
        albumArtist: faker.name.fullName(),
      ),
    ),
    totalRecordCount: faker.datatype.number(),
  );
  final mockUserId = faker.datatype.uuid();

  Widget getWidgetUT({required ItemDTO artist}) => createTestApp(
    providesOverrides: [
      jellyfinApiProvider.overrideWith((_) => mockJellyfinApi),
      baseUrlProvider.overrideWith((_) => faker.internet.url()),
      currentUserProvider.overrideWith((_) => mockUser),
    ],
    home: ArtistPage(artist: artist),
  );

  Future<HttpResponse<AlbumsWrapper>> mockGetAlbums({
    String? contributingArtistIds,
    List<String>? artistIds,
  }) {
    return mockJellyfinApi.getAlbums(
      userId: mockUserId,
      libraryId: any(named: 'libraryId'),
      type: any(named: 'type'),
      startIndex: any(named: 'startIndex'),
      limit: any(named: 'limit'),
      sortBy: any(named: 'sortBy'),
      contributingArtistIds:
          contributingArtistIds ?? any(named: 'contributingArtistIds'),
      sortOrder: any(named: 'sortOrder'),
      artistIds: artistIds ?? any(named: 'artistIds'),
      recursive: any(named: 'recursive'),
    );
  }

  setUp(() {
    mockJellyfinApi = MockJellyfinApi();
    mockAlbumsResponse = MockHttpResponse();
    mockAppearsOnResponse = MockHttpResponse();
    mockUser = MockUser();
    when(
      () => mockGetAlbums(artistIds: [mockArtist.id]),
    ).thenAnswer((_) async => mockAlbumsResponse);
    when(() => mockAlbumsResponse.data).thenReturn(mockAlbums);
    when(
      () => mockGetAlbums(contributingArtistIds: mockArtist.id),
    ).thenAnswer((_) async => mockAppearsOnResponse);
    when(() => mockAppearsOnResponse.data).thenReturn(mockAppearsOn);
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
          () => mockAppearsOnResponse.data,
        ).thenReturn(mockAppearsOn.copyWith(items: const []));
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
          () => mockAlbumsResponse.data,
        ).thenReturn(mockAlbums.copyWith(items: const []));
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
