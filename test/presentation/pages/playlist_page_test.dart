import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/pages.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart';

import '../../app_wrapper.dart';

class MockJellyfinApi extends Mock implements JellyfinApi {}

class MockHttpResponse<T> extends Mock implements HttpResponse<T> {}

class MockUser extends Mock implements User {}

class MockDownloadManagerNotifier extends AsyncNotifier<List<DownloadedSongDTO>>
    with Mock
    implements DownloadManagerNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JellyfinApi mockJellyfinApi;
  late HttpResponse<SongsWrapper> mockSongsResponse;
  late User mockUser;
  late DownloadManagerNotifier mockDownloadManagerNotifier;

  final faker = Faker.instance;
  final mockPlaylist = ItemDTO(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    serverId: faker.datatype.uuid(),
    type: 'Playlist',
    durationInTicks: faker.datatype.number(min: 10000),
    productionYear: faker.date.past(DateTime.now()).year,
    albumArtist: faker.name.fullName(),
    imageTags: {'Primary': faker.datatype.uuid()},
  );
  final mockSongs = SongsWrapper(
    items: List.generate(
      10,
      (_) => SongDTO(
        id: faker.datatype.uuid(),
        name: faker.lorem.sentence(),
        runTimeTicks: faker.datatype.number(min: 10000),
        songUserData: SongUserData(
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

  Widget getWidgetUT({required ItemDTO playlist}) => createTestApp(
    providesOverrides: [
      jellyfinApiProvider.overrideWith((_) => mockJellyfinApi),
      baseUrlProvider.overrideWith((_) => faker.internet.url()),
      currentUserProvider.overrideWith((_) => mockUser),
      downloadManagerProvider.overrideWith(() => mockDownloadManagerNotifier),
    ],
    home: PlaylistPage(playlist: playlist),
  );

  Future<HttpResponse<SongsWrapper>> mockGetPlaylistSongs({
    String? playlistId,
  }) {
    return mockJellyfinApi.getPlaylistSongs(
      userId: mockUserId,
      playlistId: playlistId ?? any(named: 'playlistId'),
      includeType: any(named: 'includeType'),
    );
  }

  setUpAll(() {
    deviceId = faker.datatype.uuid();
  });

  setUp(() {
    mockJellyfinApi = MockJellyfinApi();
    mockSongsResponse = MockHttpResponse();
    mockUser = MockUser();
    mockDownloadManagerNotifier = MockDownloadManagerNotifier();
    when(
      () => mockGetPlaylistSongs(playlistId: mockPlaylist.id),
    ).thenAnswer((_) async => mockSongsResponse);
    when(() => mockSongsResponse.data).thenReturn(mockSongs);
    when(() => mockUser.userId).thenReturn(mockUserId);
  });

  group('PlaylistPage', () {
    testWidgets(
      '- displays playlist details',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(playlist: mockPlaylist));
        await widgetTester.pump(Duration.zero);
        expect(find.text(mockPlaylist.name), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      '- displays list of songs',
      (widgetTester) async {
        await widgetTester.pumpWidget(getWidgetUT(playlist: mockPlaylist));
        await widgetTester.pump(Duration.zero);
        final songUT = mockSongs.items.first;
        final songFinder = find.byType(PlayerSongView);
        expect(songFinder, findsWidgets);
        expect(
          find.descendant(
            of: songFinder,
            matching: find.text(songUT.name ?? ''),
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
  });
}
