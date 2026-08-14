import 'dart:io';

import 'package:faker_dart/faker_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/services/download_service.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../mock_listener.dart';
import '../../provider_container.dart';

class MockDownloadService extends Mock implements DownloadService {}

class MockDownloadDatabase extends Mock implements DownloadDatabase {}

class MockMediaServerClient extends Mock implements MediaServerClient {}

class FakeFile extends Fake implements File {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer providerContainer;
  late DownloadService mockDownloadService;
  late DownloadDatabase mockDownloadDatabase;
  late MediaServerClient mockMediaServerClient;
  late MockListener<AsyncValue<List<DownloadedSong>>> mockListener;

  final faker = Faker.instance;
  final mockDeviceId = faker.datatype.uuid();
  final mockSong = LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    userData: PlaybackUserData(
      position: Duration(milliseconds: faker.datatype.number()),
      playCount: faker.datatype.number(),
      isFavorite: faker.datatype.boolean(),
      played: faker.datatype.boolean(),
    ),
    kind: ItemKind.song,
  );
  final mockAlbum = LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    kind: ItemKind.album,
  );

  DownloadTask createDownloadTask({
    String? id,
    DownloadStatus status = DownloadStatus.pending,
  }) {
    return DownloadTask(
      id: id ?? mockSong.id,
      name: faker.lorem.sentence(),
      url: faker.internet.url(),
      destination: '/downloads/${faker.lorem.word()}.mp3',
    )..status.value = status;
  }

  setUpAll(() {
    registerFallbackValue(mockSong);
    registerFallbackValue(mockAlbum);
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockDownloadService = MockDownloadService();
    mockDownloadDatabase = MockDownloadDatabase();
    mockMediaServerClient = MockMediaServerClient();
    mockListener = MockListener();
    providerContainer = createProviderContainer(
      overrides: [
        downloadServiceProvider.overrideWith((_) => mockDownloadService),
        downloadDatabaseProvider.overrideWithValue(mockDownloadDatabase),
        mediaServerClientProvider.overrideWith((_) => mockMediaServerClient),
      ],
    );
    // downloadSong reads the deviceId global (set in main() at app startup,
    // which doesn't run under tests), so seed it here.
    deviceId = mockDeviceId;
  });

  group('DownloadManagerNotifier', () {
    test(
      '- fetches downloaded songs from a database on initialization',
      () {
        when(
          () => mockDownloadDatabase.getDownloadedSongs(),
        ).thenAnswer((_) async => []);
        providerContainer.listen(
          downloadManagerProvider,
          mockListener.call,
          fireImmediately: true,
        );
        // Check if downloaded songs are fetched from database
        verify(() => mockDownloadDatabase.getDownloadedSongs()).called(1);
      },
    );

    test(
      '- can fetch a song and save it into database',
      () async {
        final mockTask = createDownloadTask(status: DownloadStatus.completed);
        when(
          () => mockDownloadService.downloadSong(
            any(),
            mockMediaServerClient,
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((_) async => mockTask);
        when(
          () => mockDownloadDatabase.insertDownloadedSong(
            any(),
            file: any(named: 'file'),
          ),
        ).thenAnswer((_) async => faker.datatype.number());
        providerContainer.listen(
          downloadManagerProvider,
          mockListener.call,
          fireImmediately: true,
        );
        // ACTION
        await expectLater(
          providerContainer
              .read(downloadManagerProvider.notifier)
              .downloadSong(mockSong),
          completes,
        );
        mockTask.dispose();
        // Check if song is fetched from backend
        verify(
          () => mockDownloadService.downloadSong(
            mockSong,
            mockMediaServerClient,
            deviceId: mockDeviceId,
          ),
        ).called(1);
        // Check if song is saved to database
        verify(
          () => mockDownloadDatabase.insertDownloadedSong(
            mockSong,
            file: any(named: 'file'),
          ),
        ).called(1);
      },
    );

    test(
      '- can fetch an album and save it into database',
      () async {
        final mockSongs = List.generate(
          faker.datatype.number(min: 1, max: 3),
          (i) => mockSong,
        );
        when(
          () => mockDownloadService.downloadSong(
            any(),
            mockMediaServerClient,
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer(
          (_) async => createDownloadTask(status: DownloadStatus.completed),
        );
        when(
          () => mockDownloadDatabase.insertDownloadedSong(
            any(),
            file: any(named: 'file'),
          ),
        ).thenAnswer((_) async => faker.datatype.number());
        when(
          () => mockDownloadDatabase.insertDownloadedAlbum(
            any(),
            files: any(named: 'files'),
          ),
        ).thenAnswer((_) async => faker.datatype.number());
        providerContainer.listen(
          downloadManagerProvider,
          mockListener.call,
          fireImmediately: true,
        );
        // ACTION
        await expectLater(
          providerContainer
              .read(downloadManagerProvider.notifier)
              .downloadAlbum(mockAlbum, mockSongs),
          completes,
        );
        // Check if each song is fetched from backend individually
        verify(
          () => mockDownloadService.downloadSong(
            mockSong,
            mockMediaServerClient,
            deviceId: mockDeviceId,
          ),
        ).called(mockSongs.length);
        // Check if each song is saved to database
        verify(
          () => mockDownloadDatabase.insertDownloadedSong(
            mockSong,
            file: any(named: 'file'),
          ),
        ).called(mockSongs.length);
        // Check if album is saved to database
        verify(
          () => mockDownloadDatabase.insertDownloadedAlbum(
            mockAlbum,
            files: any(named: 'files'),
          ),
        ).called(1);
      },
    );

    test(
      '- can delete a song from database',
      () async {
        when(
          () => mockDownloadDatabase.deleteDownloadedSong(any()),
        ).thenAnswer((_) async => faker.datatype.number());
        providerContainer.listen(
          downloadManagerProvider,
          mockListener.call,
          fireImmediately: true,
        );
        // ACTION
        await expectLater(
          providerContainer
              .read(downloadManagerProvider.notifier)
              .deleteSong(mockSong.id),
          completes,
        );
        // Check if song is deleted from database
        verify(
          () => mockDownloadDatabase.deleteDownloadedSong(mockSong.id),
        ).called(1);
      },
    );

    test(
      '- can delete an album from database',
      () async {
        when(
          () => mockDownloadDatabase.deleteDownloadedAlbum(any()),
        ).thenAnswer((_) async => faker.datatype.number());
        providerContainer.listen(
          downloadManagerProvider,
          mockListener.call,
          fireImmediately: true,
        );
        // ACTION
        await expectLater(
          providerContainer
              .read(downloadManagerProvider.notifier)
              .deleteAlbum(mockAlbum.id),
          completes,
        );
        // Check if album is deleted from database
        verify(
          () => mockDownloadDatabase.deleteDownloadedAlbum(mockAlbum.id),
        ).called(1);
      },
    );

    test(
      '- can check whether song is fetched',
      () async {
        final randomBool = faker.datatype.boolean();
        when(
          () => mockDownloadDatabase.isSongDownloaded(any()),
        ).thenAnswer((_) async => randomBool);
        providerContainer.listen(
          downloadManagerProvider,
          mockListener.call,
          fireImmediately: true,
        );
        // ACTION
        await expectLater(
          providerContainer
              .read(downloadManagerProvider.notifier)
              .isSongDownloaded(mockSong.id),
          completion(randomBool),
        );
        verify(
          () => mockDownloadDatabase.isSongDownloaded(mockSong.id),
        ).called(1);
      },
    );

    test(
      '- can check whether album is fetched',
      () async {
        final randomBool = faker.datatype.boolean();
        when(
          () => mockDownloadDatabase.isAlbumDownloaded(any()),
        ).thenAnswer((_) async => randomBool);
        providerContainer.listen(
          downloadManagerProvider,
          mockListener.call,
          fireImmediately: true,
        );
        // ACTION
        await expectLater(
          providerContainer
              .read(downloadManagerProvider.notifier)
              .isAlbumDownloaded(mockAlbum.id),
          completion(randomBool),
        );
        verify(
          () => mockDownloadDatabase.isAlbumDownloaded(mockAlbum.id),
        ).called(1);
      },
    );

    test(
      '- returns list of fetched albums',
      () async {
        final mockAlbums = List.generate(
          faker.datatype.number(min: 1, max: 3),
          (i) => DownloadedAlbum(
            item: LibraryItem(
              id: faker.datatype.uuid(),
              name: faker.lorem.sentence(),
              kind: ItemKind.album,
            ),
            sizeInBytes: faker.datatype.number(),
            downloadDate: DateTime.now(),
          ),
        );
        when(
          () => mockDownloadDatabase.getDownloadedAlbums(),
        ).thenAnswer((_) async => mockAlbums);
        providerContainer.listen(
          downloadManagerProvider,
          mockListener.call,
          fireImmediately: true,
        );
        // ACTION
        await expectLater(
          providerContainer
              .read(downloadManagerProvider.notifier)
              .getDownloadedAlbums(),
          completion(mockAlbums),
        );
        verify(() => mockDownloadDatabase.getDownloadedAlbums()).called(1);
      },
    );
  });
}
