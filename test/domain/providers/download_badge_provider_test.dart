import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/download_service.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockDownloadService extends Mock implements DownloadService {}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

LibraryItem _song(String id) =>
    LibraryItem(id: id, name: 'Song $id', kind: ItemKind.song, albumId: 'al');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const album = LibraryItem(id: 'al', name: 'Album', kind: ItemKind.album);
  const playlist = LibraryItem(id: 'pl', name: 'Mix', kind: ItemKind.playlist);

  late Directory filesDir;
  late DownloadDatabase database;
  late _MockDownloadService service;
  late _MockMediaServerClient client;
  late ProviderContainer container;
  Completer<void>? gate;

  setUpAll(() {
    registerFallbackValue(_song('fallback'));
    registerFallbackValue(ImageKind.primary);
    registerFallbackValue(_MockMediaServerClient());
  });

  setUp(() async {
    deviceId = 'test-device';
    filesDir = await Directory.systemTemp.createTemp('download_badge_test');
    await databaseFactory.setDatabasesPath(join(filesDir.path, 'db'));
    database = DownloadDatabase(serverId: 'server');
    service = _MockDownloadService();
    client = _MockMediaServerClient();
    gate = null;

    when(
      () =>
          service.downloadSong(any(), any(), deviceId: any(named: 'deviceId')),
    ).thenAnswer((invocation) async {
      final song = invocation.positionalArguments.first as LibraryItem;
      await gate?.future;
      final file = File(join(filesDir.path, '${song.id}.flac'))
        ..writeAsBytesSync([1, 2, 3]);
      return DownloadTask(
        id: song.id,
        name: song.name,
        url: 'http://server/${song.id}',
        destination: file.path,
      )..status.value = DownloadStatus.completed;
    });
    when(
      () => service.downloadAlbumCover(any(), any()),
    ).thenAnswer((_) async => null);
    when(
      () => client.imageUri(any(), kind: any(named: 'kind')),
    ).thenReturn(null);

    container = ProviderContainer(
      overrides: [
        downloadServiceProvider.overrideWith((_) => service),
        downloadDatabaseProvider.overrideWithValue(database),
        mediaServerClientProvider.overrideWith((_) => client),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    if (filesDir.existsSync()) await filesDir.delete(recursive: true);
  });

  Future<DownloadBadge?> badgeFor(LibraryItem item) async {
    final key = (item.kind, item.id);
    final sub = container.listen(downloadBadgeProvider(key), (_, _) {});
    await container.read(downloadManagerProvider.future);
    await container.read(downloadedCollectionsProvider.future);
    final badge = container.read(downloadBadgeProvider(key));
    sub.close();
    return badge;
  }

  DownloadManagerNotifier manager() =>
      container.read(downloadManagerProvider.notifier);

  test('- shows nothing for items that are not downloaded', () async {
    expect(await badgeFor(album), isNull);
    expect(await badgeFor(playlist), isNull);
  });

  test('- marks downloaded albums and playlists', () async {
    await manager().downloadAlbum(album, [_song('a')]);
    await manager().downloadPlaylist(playlist, [_song('b')]);

    expect(await badgeFor(album), DownloadBadge.downloaded);
    expect(await badgeFor(playlist), DownloadBadge.downloaded);
  });

  test('- shows downloading while the download runs', () async {
    gate = Completer<void>();
    final albumDownload = manager().downloadAlbum(album, [_song('a')]);
    final playlistDownload = manager().downloadPlaylist(playlist, [
      _song('b'),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(await badgeFor(album), DownloadBadge.downloading);
    expect(await badgeFor(playlist), DownloadBadge.downloading);

    gate!.complete();
    await (albumDownload, playlistDownload).wait;

    expect(await badgeFor(album), DownloadBadge.downloaded);
    expect(await badgeFor(playlist), DownloadBadge.downloaded);
  });

  test('- reports progress across the whole album', () async {
    final tasks = <String, DownloadTask>{};
    when(
      () =>
          service.downloadSong(any(), any(), deviceId: any(named: 'deviceId')),
    ).thenAnswer((invocation) async {
      final song = invocation.positionalArguments.first as LibraryItem;
      final file = File(join(filesDir.path, '${song.id}.flac'))
        ..writeAsBytesSync([1, 2, 3]);
      return tasks[song.id] = DownloadTask(
        id: song.id,
        name: song.name,
        url: 'http://server/${song.id}',
        destination: file.path,
      )..status.value = DownloadStatus.downloading;
    });
    await container.read(downloadManagerProvider.future);
    double? progress() => container.read(downloadProgressProvider(album.id));
    Future<void> until(bool Function() done) async {
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!done() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    final download = manager().downloadAlbum(album, [_song('a'), _song('b')]);
    await until(() => tasks.containsKey('a'));
    expect(progress(), 0);

    tasks['a']!.progress.value = 0.5;
    expect(progress(), 0.25);

    tasks['a']!.status.value = DownloadStatus.completed;
    await until(() => tasks.containsKey('b'));
    expect(progress(), 0.5);

    tasks['b']!.progress.value = 0.5;
    expect(progress(), 0.75);

    tasks['b']!.status.value = DownloadStatus.completed;
    await download;
    expect(progress(), isNull);
    expect(await badgeFor(album), DownloadBadge.downloaded);
  });

  test('- clears the badge once the download is deleted', () async {
    await manager().downloadPlaylist(playlist, [_song('b')]);
    expect(await badgeFor(playlist), DownloadBadge.downloaded);

    await manager().deletePlaylist(playlist.id);

    expect(await badgeFor(playlist), isNull);
  });

  test('- does not mix up an album and a playlist sharing an id', () async {
    await manager().downloadPlaylist(playlist, [_song('b')]);

    expect(
      await badgeFor(album.copyWith(id: playlist.id)),
      isNull,
    );
  });

  test('- never badges artists', () async {
    await manager().downloadAlbum(album, [_song('a')]);

    expect(
      await badgeFor(album.copyWith(kind: ItemKind.artist)),
      isNull,
    );
  });
}
