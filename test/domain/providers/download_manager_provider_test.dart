import 'dart:io';

import 'package:faker_dart/faker_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/services/download_service.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../mock_listener.dart';
import '../../provider_container.dart';

class MockDownloadService extends Mock implements DownloadService {}

class MockDownloadDatabase extends Mock implements DownloadDatabase {}

class MockUser extends Mock implements User {}

class FakeFile extends Fake implements File {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer providerContainer;
  late DownloadService mockDownloadService;
  late DownloadDatabase mockDownloadDatabase;
  late User mockUser;
  late MockListener<AsyncValue<List<DownloadedSongDTO>>> mockListener;

  final faker = Faker.instance;
  final mockBaseUrl = faker.internet.url();
  final mockUserId = faker.datatype.uuid();
  final mockToken = faker.datatype.string();
  final mockSong = ItemDTO(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    runTimeTicks: faker.datatype.number(),
    userData: UserData(
      playbackPositionTicks: faker.datatype.number(),
      playCount: faker.datatype.number(),
      isFavorite: faker.datatype.boolean(),
      played: faker.datatype.boolean(),
    ),
    type: 'Song',
  );
  final mockAlbum = ItemDTO(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    runTimeTicks: faker.datatype.number(),
    type: 'Album',
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
    mockUser = MockUser();
    mockListener = MockListener();
    providerContainer = createProviderContainer(
      overrides: [
        downloadServiceProvider.overrideWithValue(mockDownloadService),
        downloadDatabaseProvider.overrideWithValue(mockDownloadDatabase),
        baseUrlProvider.overrideWith((_) => mockBaseUrl),
        currentUserProvider.overrideWith((_) => mockUser),
      ],
    );
    when(() => mockUser.userId).thenReturn(mockUserId);
    when(() => mockUser.token).thenReturn(mockToken);
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
          () => mockDownloadService.downloadSong(any(), any(), any()),
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
            mockBaseUrl,
            mockToken,
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
        final mockTasks = List.generate(
          mockSongs.length,
          (i) => createDownloadTask(status: DownloadStatus.completed),
        );
        when(
          () => mockDownloadService.downloadSongs(any(), any(), any()),
        ).thenAnswer((_) async => mockTasks);
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
        for (final task in mockTasks) {
          task.dispose();
        }
        // Check if songs are fetched from backend
        verify(
          () => mockDownloadService.downloadSongs(
            mockSongs,
            mockBaseUrl,
            mockToken,
          ),
        ).called(1);
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
          (i) => DownloadedAlbumDTO(
            id: faker.datatype.uuid(),
            name: faker.lorem.sentence(),
            runTimeTicks: faker.datatype.number(),
            type: 'Album',
            sizeInBytes: faker.datatype.number(),
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
