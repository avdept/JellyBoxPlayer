import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/pages.dart' hide LibraryPage;
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../app_wrapper.dart';
import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class MockUser extends Mock implements User {}

class MockDownloadManagerNotifier extends AsyncNotifier<List<DownloadedSongDTO>>
    with Mock
    implements DownloadManagerNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MediaServerClient mockMediaServerClient;
  late User mockUser;
  late DownloadManagerNotifier mockDownloadManagerNotifier;

  final faker = Faker.instance;
  final mockBaseUrl = faker.internet.url();
  final mockPlaylist = LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    kind: ItemKind.playlist,
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
  final mockUserId = faker.datatype.uuid();

  Widget getWidgetUT({required LibraryItem playlist}) => createTestApp(
    providerContainer: createProviderContainer(
      overrides: [
        mediaServerClientProvider.overrideWith((_) => mockMediaServerClient),
        baseUrlProvider.overrideWith((_) => mockBaseUrl),
        currentUserProvider.overrideWith((_) => mockUser),
        downloadManagerProvider.overrideWith(() => mockDownloadManagerNotifier),
      ],
    ),
    home: PlaylistPage(playlist: playlist),
  );

  Future<LibraryPage> mockGetPlaylistSongs({String? playlistId}) {
    return mockMediaServerClient.getPlaylistSongs(
      userId: mockUserId,
      playlistId: playlistId ?? any(named: 'playlistId'),
    );
  }

  setUpAll(() {
    registerFallbackValue(ImageKind.primary);
    deviceId = faker.datatype.uuid();
  });

  setUp(() {
    mockMediaServerClient = MockMediaServerClient();
    mockUser = MockUser();
    mockDownloadManagerNotifier = MockDownloadManagerNotifier();
    when(
      () => mockMediaServerClient.imageUrl(
        id: any(named: 'id'),
        tagId: any(named: 'tagId'),
        kind: any(named: 'kind'),
        size: any(named: 'size'),
      ),
    ).thenReturn('https://example.com/image.jpg');
    when(
      () => mockGetPlaylistSongs(playlistId: mockPlaylist.id),
    ).thenAnswer((_) async => mockSongs);
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
  });
}
