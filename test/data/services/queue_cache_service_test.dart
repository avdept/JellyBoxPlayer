import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/downloads/cache_downloader.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/services/album_cover_store.dart';
import 'package:jplayer/src/data/services/queue_cache_service.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/queue_cache_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeDownloader implements CacheDownloader {
  _FakeDownloader(this._directory);

  final Directory _directory;
  final requested = <String>[];
  final cancelled = <String>[];
  final failIds = <String>{};
  int bytes = 1024;

  @override
  Future<String> directoryPath() async => _directory.path;

  @override
  Future<String?> fetch({
    required String id,
    required String url,
    required String fileName,
  }) async {
    requested.add(id);
    if (failIds.contains(id)) return null;
    final file = File(join(_directory.path, fileName))
      ..writeAsBytesSync(List.filled(bytes, 0));
    return file.path;
  }

  @override
  Future<void> cancel(String id) async => cancelled.add(id);
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory filesDir;
  late Directory coversDir;
  late List<Uri> coverRequests;
  late _FakeDownloader downloader;
  late QueueCacheDatabase database;
  late QueueCacheService service;
  late MediaServerClient client;

  LibraryItem song(String id) =>
      LibraryItem(id: id, name: 'song $id', kind: ItemKind.song);

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('queue_cache_svc_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
    registerFallbackValue(song('fallback'));
    registerFallbackValue(StreamTargetProfile.download(isAndroid: false));
    registerFallbackValue(ImageKind.primary);
  });

  setUp(() async {
    filesDir = await Directory.systemTemp.createTemp('queue_cache_svc');
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));

    coversDir = await Directory.systemTemp.createTemp('queue_cache_covers');
    DownloadPaths.root = coversDir.path;
    coverRequests = [];

    downloader = _FakeDownloader(filesDir);
    database = QueueCacheDatabase(DownloadDatabase(serverId: 'server-1'));
    service = QueueCacheService(
      database: database,
      downloads: DownloadDatabase(serverId: 'server-1'),
      downloader: downloader,
      deviceId: 'test-device',
      covers: AlbumCoverStore(
        fetch: (uri) async {
          coverRequests.add(uri);
          return [1, 2, 3];
        },
      ),
    );
    client = _MockMediaServerClient();
    when(
      () => client.resolveStreamSource(
        any(),
        playSessionId: any(named: 'playSessionId'),
        target: any(named: 'target'),
      ),
    ).thenAnswer(
      (_) async => StreamSource(
        uri: Uri.parse('http://server/audio/stream'),
        isHls: false,
        outputContainer: 'flac',
        mimeType: 'audio/flac',
      ),
    );
  });

  tearDown(() async {
    DownloadPaths.root = null;
    if (filesDir.existsSync()) await filesDir.delete(recursive: true);
    if (coversDir.existsSync()) await coversDir.delete(recursive: true);
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  group('QueueCacheService', () {
    test('- caches a song through the download profile', () async {
      final path = await service.cache(song('a'), client);

      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);
      expect(await database.pathOf('a'), path);
      expect(downloader.requested, ['a']);

      final captured = verify(
        () => client.resolveStreamSource(
          any(),
          playSessionId: captureAny(named: 'playSessionId'),
          target: captureAny(named: 'target'),
        ),
      ).captured;
      expect(captured.first, 'cache-test-device-a');
      expect((captured.last as StreamTargetProfile).supportsHls, isFalse);
    });

    test('- stores the album cover alongside the audio', () async {
      final artwork = Uri.parse('http://server/Items/album-1/Images/Primary');
      when(
        () => client.imageUri(
          any(),
          kind: any(named: 'kind'),
          size: any(named: 'size'),
        ),
      ).thenReturn(artwork);
      const track = LibraryItem(
        id: 'a',
        name: 'song a',
        kind: ItemKind.song,
        albumId: 'album-1',
      );

      await service.cache(track, client);

      expect(coverRequests, [artwork]);
      expect(
        File(
          join(coversDir.path, 'album-1', DownloadPaths.coverFileName),
        ).existsSync(),
        isTrue,
      );
    });

    test('- skips the cover when the song has no album', () async {
      await service.cache(song('a'), client);

      expect(coverRequests, isEmpty);
    });

    test('- leaves nothing behind when a fetch fails', () async {
      downloader.failIds.add('a');

      expect(await service.cache(song('a'), client), isNull);
      expect(await database.cachedIds(), isEmpty);
    });

    test('- leaves nothing behind when the server errors', () async {
      when(
        () => client.resolveStreamSource(
          any(),
          playSessionId: any(named: 'playSessionId'),
          target: any(named: 'target'),
        ),
      ).thenThrow(Exception('offline'));

      expect(await service.cache(song('a'), client), isNull);
      expect(await database.cachedIds(), isEmpty);
      expect(downloader.requested, isEmpty);
    });

    test('- evicts least recently used entries outside the queue', () async {
      downloader.bytes = 1000;
      await service.cache(song('a'), client);
      await settle();
      await service.cache(song('b'), client);
      await settle();
      await service.cache(song('c'), client);

      await service.enforceLimit(2000, keepIds: {'c'});

      expect(await database.cachedIds(), {'b', 'c'});
    });

    test('- keeps queued entries even when over the limit', () async {
      downloader.bytes = 1000;
      await service.cache(song('a'), client);
      await settle();
      await service.cache(song('b'), client);

      await service.enforceLimit(500, keepIds: {'a', 'b'});

      expect(await database.cachedIds(), {'a', 'b'});
    });

    test('- keeps the playing queue when the limit is switched off', () async {
      await service.cache(song('a'), client);
      await settle();
      await service.cache(song('b'), client);

      await service.enforceLimit(0, keepIds: {'a'});

      expect(await database.cachedIds(), {'a'});
    });

    test('- sheds everything once the queue moves on', () async {
      await service.cache(song('a'), client);

      await service.enforceLimit(0);

      expect(await database.cachedIds(), isEmpty);
      expect(await database.totalBytes(), 0);
    });

    test('- purging clears rows and stray files alike', () async {
      await service.cache(song('a'), client);
      final stray = File(join(filesDir.path, 'stray.flac'))
        ..writeAsBytesSync([1, 2, 3]);

      await service.purge();

      expect(await database.cachedIds(), isEmpty);
      expect(stray.existsSync(), isFalse);
      expect(filesDir.listSync(), isEmpty);
    });

    test('- reconciles rows whose file vanished', () async {
      final path = await service.cache(song('a'), client);
      await File(path!).delete();

      await service.reconcile();

      expect(await database.cachedIds(), isEmpty);
    });

    test("- reconciling drops another server's entries", () async {
      final other = QueueCacheDatabase(DownloadDatabase(serverId: 'server-2'));
      await service.cache(song('a'), client);
      final theirFile = File(join(filesDir.path, 'theirs.flac'))
        ..writeAsBytesSync([1, 2, 3]);
      await other.insert(song('b'), file: theirFile);

      await service.reconcile();

      expect(await database.cachedIds(), {'a'});
      expect(await other.cachedIds(), isEmpty);
      expect(theirFile.existsSync(), isFalse);
    });

    test('- reconciling keeps a downloaded album cover', () async {
      final downloads = DownloadDatabase(serverId: 'server-1');
      const album = LibraryItem(
        id: 'album-kept',
        name: 'Album',
        kind: ItemKind.album,
      );
      await downloads.insertDownloadedAlbum(
        album,
        files: [File(join(filesDir.path, 'placeholder'))..writeAsBytesSync([1])],
      );
      final kept = File(
        join(coversDir.path, 'album-kept', DownloadPaths.coverFileName),
      );
      await kept.parent.create(recursive: true);
      kept.writeAsBytesSync([1, 2, 3]);
      final orphan = File(
        join(coversDir.path, 'album-gone', DownloadPaths.coverFileName),
      );
      await orphan.parent.create(recursive: true);
      orphan.writeAsBytesSync([1, 2, 3]);

      await service.reconcile();

      expect(kept.existsSync(), isTrue);
      expect(orphan.existsSync(), isFalse);
    });

    test('- prunes rows the OS reclaimed', () async {
      final path = await service.cache(song('a'), client);
      await File(path!).delete();

      expect(await service.pruneMissing(), 1);
      expect(await database.totalBytes(), 0);
    });

    test('- reconciles files nothing knows about', () async {
      await service.cache(song('a'), client);
      final orphan = File(join(filesDir.path, 'orphan.flac'))
        ..writeAsBytesSync([1, 2, 3]);

      await service.reconcile();

      expect(await database.cachedIds(), {'a'});
      expect(orphan.existsSync(), isFalse);
    });
  });
}
