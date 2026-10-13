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

import '../../provider_container.dart';

class MockDownloadService extends Mock implements DownloadService {}

class MockDownloadDatabase extends Mock implements DownloadDatabase {}

class MockMediaServerClient extends Mock implements MediaServerClient {}

class FakeFile extends Fake implements File {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late DownloadService service;
  late DownloadDatabase database;
  late MediaServerClient client;

  final faker = Faker.instance;
  final mockDeviceId = faker.datatype.uuid();
  final mockSong = LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    kind: ItemKind.song,
    albumId: 'album-1',
  );
  const mockAlbum = LibraryItem(
    id: 'album-1',
    name: 'Album',
    kind: ItemKind.album,
  );
  const playlist = LibraryItem(
    id: 'playlist-1',
    name: 'Mix',
    kind: ItemKind.playlist,
  );

  LibraryItem song(String id) =>
      LibraryItem(id: id, name: id, kind: ItemKind.song);

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

  DownloadManager manager() => container.read(downloadManagerProvider);

  int revision() => container.read(downloadsRevisionProvider);

  Map<String, DownloadTask> trackedSongs() =>
      container.read(downloadActivityProvider).songs;

  void stubDownloads(DownloadStatus status) {
    when(
      () =>
          service.downloadSong(any(), any(), deviceId: any(named: 'deviceId')),
    ).thenAnswer((invocation) async {
      final item = invocation.positionalArguments.first as LibraryItem;
      return createDownloadTask(id: item.id, status: status);
    });
  }

  setUpAll(() {
    registerFallbackValue(mockSong);
    registerFallbackValue(FakeFile());
    registerFallbackValue(<String>[]);
    registerFallbackValue(MockMediaServerClient());
  });

  setUp(() {
    service = MockDownloadService();
    database = MockDownloadDatabase();
    client = MockMediaServerClient();
    container = createProviderContainer(
      overrides: [
        downloadServiceProvider.overrideWith((_) => service),
        downloadDatabaseProvider.overrideWithValue(database),
        mediaServerClientProvider.overrideWith((_) => client),
      ],
    );
    deviceId = mockDeviceId;
    when(
      () => database.insertDownloadedSong(
        any(),
        file: any(named: 'file'),
        pending: any(named: 'pending'),
      ),
    ).thenAnswer((_) async => 1);
    when(
      () => database.insertDownloadedAlbum(any(), files: any(named: 'files')),
    ).thenAnswer((_) async => 1);
    when(
      () => database.insertDownloadedPlaylist(
        any(),
        songs: any(named: 'songs'),
        files: any(named: 'files'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => database.getDownloadedSongPath(any()),
    ).thenAnswer((_) async => null);
    when(() => database.pruneSongs(any())).thenAnswer((_) async {});
    when(
      () => service.downloadAlbumCover(any(), any()),
    ).thenAnswer((_) async => FakeFile());
  });

  group('DownloadManager', () {
    test('- downloads a song, stores it and announces the change', () async {
      stubDownloads(DownloadStatus.completed);

      await manager().downloadSong(mockSong);

      verify(
        () => service.downloadSong(mockSong, client, deviceId: mockDeviceId),
      ).called(1);
      verify(
        () => database.insertDownloadedSong(
          mockSong,
          file: any(named: 'file'),
          pending: false,
        ),
      ).called(1);
      verify(() => service.downloadAlbumCover(mockAlbum.id, any())).called(1);
      expect(revision(), 1);
    });

    test('- stores nothing when the song download fails', () async {
      stubDownloads(DownloadStatus.failed);

      await manager().downloadSong(mockSong);

      verifyNever(
        () => database.insertDownloadedSong(
          any(),
          file: any(named: 'file'),
          pending: any(named: 'pending'),
        ),
      );
      expect(revision(), 0);
      expect(trackedSongs(), isEmpty);
    });

    test('- downloads every song of an album and then the album', () async {
      final songs = [song('a'), song('b'), song('c')];
      stubDownloads(DownloadStatus.completed);

      await manager().downloadAlbum(mockAlbum, songs);

      for (final item in songs) {
        verify(
          () => service.downloadSong(item, client, deviceId: mockDeviceId),
        ).called(1);
        verify(
          () => database.insertDownloadedSong(
            item,
            file: any(named: 'file'),
            pending: true,
          ),
        ).called(1);
      }
      verify(
        () => database.insertDownloadedAlbum(
          mockAlbum,
          files: any(named: 'files'),
        ),
      ).called(1);
      expect(revision(), 1);
    });

    test('- skips songs that are already on disk', () async {
      final existing = File('${Directory.systemTemp.path}/existing.flac')
        ..writeAsBytesSync([1]);
      addTearDown(existing.delete);
      when(
        () => database.getDownloadedSongPath('a'),
      ).thenAnswer((_) async => existing.path);
      stubDownloads(DownloadStatus.completed);

      await manager().downloadAlbum(mockAlbum, [song('a'), song('b')]);

      verifyNever(
        () => service.downloadSong(
          song('a'),
          any(),
          deviceId: any(named: 'deviceId'),
        ),
      );
      verify(
        () => service.downloadSong(
          song('b'),
          any(),
          deviceId: any(named: 'deviceId'),
        ),
      ).called(1);
      final files =
          verify(
                () => database.insertDownloadedAlbum(
                  any(),
                  files: captureAny(named: 'files'),
                ),
              ).captured.single
              as List<File>;
      expect(files, hasLength(2));
    });

    test(
      '- a liked-songs sync keeps the local order and puts new likes first',
      () async {
        const liked = LibraryItem(
          id: 'jellybox:liked-songs:user-1',
          name: 'Liked songs',
          kind: ItemKind.playlist,
        );
        when(
          () => database.getPlaylistSongIds(liked.id),
        ).thenAnswer((_) async => ['c', 'a', 'gone']);
        stubDownloads(DownloadStatus.completed);

        final changed = await manager().syncPlaylist(
          liked,
          [song('a'), song('new'), song('c')],
          keepLocalOrder: true,
        );

        expect(changed, isTrue);
        final stored =
            verify(
                  () => database.insertDownloadedPlaylist(
                    any(),
                    songs: captureAny(named: 'songs'),
                    files: any(named: 'files'),
                  ),
                ).captured.single
                as List<LibraryItem>;
        expect(stored.map((s) => s.id), ['new', 'c', 'a']);
        final pruned = verify(
          () => database.pruneSongs(captureAny()),
        ).captured.single;
        expect(pruned, ['gone']);
      },
    );

    test('- a sync with nothing new leaves the store alone', () async {
      when(
        () => database.getPlaylistSongIds(playlist.id),
      ).thenAnswer((_) async => ['a', 'b']);

      final changed = await manager().syncPlaylist(playlist, [
        song('a'),
        song('b'),
      ]);

      expect(changed, isFalse);
      verifyNever(
        () => service.downloadSong(
          any(),
          any(),
          deviceId: any(named: 'deviceId'),
        ),
      );
      expect(revision(), 0);
    });

    test('- deletes a song and announces the change', () async {
      when(
        () => database.deleteDownloadedSong(mockSong.id),
      ).thenAnswer((_) async => 1);

      await manager().deleteSong(mockSong.id);

      verify(() => database.deleteDownloadedSong(mockSong.id)).called(1);
      expect(revision(), 1);
    });

    test('- deletes an album and announces the change', () async {
      when(
        () => database.deleteDownloadedAlbum(mockAlbum.id),
      ).thenAnswer((_) async {});

      await manager().deleteAlbum(mockAlbum.id);

      verify(() => database.deleteDownloadedAlbum(mockAlbum.id)).called(1);
      expect(revision(), 1);
    });

    test(
      '- keeps a finished song task until the next download starts',
      () async {
        final tasks = <String, DownloadTask>{};
        when(
          () => service.downloadSong(
            any(),
            any(),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((invocation) async {
          final item = invocation.positionalArguments.first as LibraryItem;
          return tasks[item.id] = createDownloadTask(
            id: item.id,
            status: DownloadStatus.downloading,
          );
        });

        final first = manager().downloadSong(song('a'));
        await untilCalled(
          () => service.downloadSong(
            song('a'),
            any(),
            deviceId: any(named: 'deviceId'),
          ),
        );
        await pumpEventQueue();
        expect(trackedSongs().keys, ['a']);

        tasks['a']!.status.value = DownloadStatus.completed;
        await first;
        expect(trackedSongs().keys, ['a']);

        final second = manager().downloadSong(song('b'));
        await untilCalled(
          () => service.downloadSong(
            song('b'),
            any(),
            deviceId: any(named: 'deviceId'),
          ),
        );
        await pumpEventQueue();
        expect(trackedSongs().keys, ['b']);

        tasks['b']!.status.value = DownloadStatus.completed;
        await second;
      },
    );

    test('- forgets a deleted song task', () async {
      stubDownloads(DownloadStatus.completed);
      when(
        () => database.deleteDownloadedSong(mockSong.id),
      ).thenAnswer((_) async => 1);
      await manager().downloadSong(mockSong);
      expect(trackedSongs().keys, [mockSong.id]);

      await manager().deleteSong(mockSong.id);

      expect(trackedSongs(), isEmpty);
    });

    test('- prunes what it fetched when a song download throws', () async {
      final first = song('song-a');
      final second = song('song-b');
      when(
        () => service.downloadSong(
          first,
          any(),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer(
        (_) async =>
            createDownloadTask(id: first.id, status: DownloadStatus.completed),
      );
      when(
        () => service.downloadSong(
          second,
          any(),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenThrow(const SocketException('offline'));

      await manager().downloadPlaylist(playlist, [first, second]);

      final pruned =
          verify(() => database.pruneSongs(captureAny())).captured.single
              as Iterable<String>;
      expect(pruned, [first.id]);
      verifyNever(
        () => database.insertDownloadedPlaylist(
          any(),
          songs: any(named: 'songs'),
          files: any(named: 'files'),
        ),
      );
      expect(container.read(downloadActivityProvider).collections, isEmpty);
      expect(revision(), 1);
    });

    test('- a stop during song preparation still cancels that song', () async {
      final first = song('song-a');
      final second = song('song-b');
      final secondTask = createDownloadTask(
        id: second.id,
        status: DownloadStatus.downloading,
      );
      when(
        () => database.deleteDownloadedPlaylist(any()),
      ).thenAnswer((_) async {});
      when(
        () => service.downloadSong(
          first,
          any(),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer(
        (_) async =>
            createDownloadTask(id: first.id, status: DownloadStatus.completed),
      );
      when(
        () => service.downloadSong(
          second,
          any(),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer((_) async {
        await manager().deletePlaylist(playlist.id);
        return secondTask;
      });
      when(() => service.cancelDownload(second.id)).thenAnswer((_) async {
        secondTask.status.value = DownloadStatus.canceled;
      });

      await manager().downloadPlaylist(playlist, [first, second]);

      verify(() => service.cancelDownload(second.id)).called(1);
      final pruned =
          verify(() => database.pruneSongs(captureAny())).captured.single
              as Iterable<String>;
      expect(pruned, [first.id]);
      verifyNever(
        () => database.insertDownloadedSong(
          second,
          file: any(named: 'file'),
          pending: any(named: 'pending'),
        ),
      );
    });

    test('- stopping a playlist download prunes what it fetched', () async {
      final first = song('song-a');
      final second = song('song-b');
      final firstTask = createDownloadTask(
        id: first.id,
        status: DownloadStatus.completed,
      );
      final secondTask = createDownloadTask(
        id: second.id,
        status: DownloadStatus.downloading,
      );
      when(
        () => database.deleteDownloadedPlaylist(any()),
      ).thenAnswer((_) async {});
      when(
        () => service.downloadSong(
          first,
          any(),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer((_) async => firstTask);
      when(
        () => service.downloadSong(
          second,
          any(),
          deviceId: any(named: 'deviceId'),
        ),
      ).thenAnswer((_) async => secondTask);
      when(() => service.cancelDownload(second.id)).thenAnswer((_) async {
        secondTask.status.value = DownloadStatus.canceled;
      });

      final download = manager().downloadPlaylist(playlist, [first, second]);
      await untilCalled(
        () => service.downloadSong(
          second,
          any(),
          deviceId: any(named: 'deviceId'),
        ),
      );
      await manager().deletePlaylist(playlist.id);
      await download;

      verify(() => service.cancelDownload(second.id)).called(1);
      final pruned =
          verify(() => database.pruneSongs(captureAny())).captured.single
              as Iterable<String>;
      expect(pruned, [first.id]);
      verifyNever(
        () => database.insertDownloadedPlaylist(
          any(),
          songs: any(named: 'songs'),
          files: any(named: 'files'),
        ),
      );
      expect(
        container.read(downloadActivityProvider).collections,
        isEmpty,
      );
    });
  });
}
