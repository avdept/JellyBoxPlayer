import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/queue_cache_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory filesDir;

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('queue_cache_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
  });

  setUp(() async {
    filesDir = await Directory.systemTemp.createTemp('queue_cache_files');
  });

  tearDown(() async {
    if (filesDir.existsSync()) await filesDir.delete(recursive: true);
  });

  LibraryItem song(String id) =>
      LibraryItem(id: id, name: 'song $id', kind: ItemKind.song);

  File cachedFile(String id, {int bytes = 1024}) {
    final file = File(join(filesDir.path, '$id.flac'))
      ..writeAsBytesSync(List.filled(bytes, 0));
    return file;
  }

  Future<void> deleteDb() async {
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
  }

  Future<QueueCacheDatabase> freshDb({String serverId = 'server-1'}) async {
    await deleteDb();
    return QueueCacheDatabase(DownloadDatabase(serverId: serverId));
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  group('QueueCacheDatabase', () {
    test('- stores a cached entry and reads it back', () async {
      final database = await freshDb();
      final file = cachedFile('a', bytes: 2048);

      await database.insert(song('a'), file: file);

      expect(await database.pathOf('a'), file.path);
      expect(await database.cachedIds(), {'a'});
      expect(await database.totalBytes(), 2048);
    });

    test('- skips entries whose file vanished', () async {
      final database = await freshDb();
      final kept = cachedFile('a');
      final lost = cachedFile('b');
      await database.insert(song('a'), file: kept);
      await database.insert(song('b'), file: lost);

      await lost.delete();

      expect(await database.pathsFor(['a', 'b']), {'a': kept.path});
    });

    test('- returns nothing when no ids are asked for', () async {
      final database = await freshDb();
      await database.insert(song('a'), file: cachedFile('a'));

      expect(await database.pathsFor(const []), isEmpty);
    });

    test('- touching an entry moves it off the eviction front', () async {
      final database = await freshDb();
      await database.insert(song('a'), file: cachedFile('a'));
      await settle();
      await database.insert(song('b'), file: cachedFile('b'));
      await settle();

      await database.touch('a');

      final candidates = await database.leastRecentlyUsed();
      expect([for (final entry in candidates) entry.id], ['b', 'a']);
    });

    test('- never offers the current queue for eviction', () async {
      final database = await freshDb();
      await database.insert(song('a'), file: cachedFile('a'));
      await settle();
      await database.insert(song('b'), file: cachedFile('b'));

      final candidates = await database.leastRecentlyUsed(
        excludedIds: {'a'},
      );

      expect([for (final entry in candidates) entry.id], ['b']);
    });

    test('- deleting an entry removes its row and its file', () async {
      final database = await freshDb();
      final file = cachedFile('a');
      await database.insert(song('a'), file: file);

      await database.delete('a');

      expect(await database.cachedIds(), isEmpty);
      expect(await database.totalBytes(), 0);
      expect(file.existsSync(), isFalse);
    });

    test('- clearing only touches the current server', () async {
      final first = await freshDb();
      final second = QueueCacheDatabase(
        DownloadDatabase(serverId: 'server-2'),
      );
      final mine = cachedFile('a');
      final theirs = cachedFile('b');
      await first.insert(song('a'), file: mine);
      await second.insert(song('b'), file: theirs);

      await first.deleteAll();

      expect(await first.cachedIds(), isEmpty);
      expect(await second.cachedIds(), {'b'});
      expect(mine.existsSync(), isFalse);
      expect(theirs.existsSync(), isTrue);
    });

    test('- reads back a long queue in chunks', () async {
      final database = await freshDb();
      final ids = [for (var i = 0; i < 1200; i++) 'song-$i'];
      for (final id in ids.take(3)) {
        await database.insert(song(id), file: cachedFile(id));
      }

      final paths = await database.pathsFor(ids);

      expect(paths.keys, ids.take(3));
    });

    test('- prunes rows whose file vanished', () async {
      final database = await freshDb();
      final kept = cachedFile('a');
      final lost = cachedFile('b', bytes: 2048);
      await database.insert(song('a'), file: kept);
      await database.insert(song('b'), file: lost);
      await lost.delete();

      expect(await database.pruneMissing(), 1);
      expect(await database.cachedIds(), {'a'});
      expect(await database.totalBytes(), 1024);
    });

    test('- drops entries belonging to other servers', () async {
      final mine = await freshDb();
      final theirs = QueueCacheDatabase(
        DownloadDatabase(serverId: 'server-2'),
      );
      final myFile = cachedFile('a');
      final theirFile = cachedFile('b');
      await mine.insert(song('a'), file: myFile);
      await theirs.insert(song('b'), file: theirFile);

      await mine.deleteForeignServers();

      expect(await mine.cachedIds(), {'a'});
      expect(await theirs.cachedIds(), isEmpty);
      expect(myFile.existsSync(), isTrue);
      expect(theirFile.existsSync(), isFalse);
    });

    test('- keeps every server when it has no server id', () async {
      final legacy = await freshDb(serverId: '');
      final scoped = QueueCacheDatabase(
        DownloadDatabase(serverId: 'server-2'),
      );
      await scoped.insert(song('b'), file: cachedFile('b'));

      await legacy.deleteForeignServers();

      expect(await scoped.cachedIds(), {'b'});
    });

    test('- sees file paths across every server', () async {
      final first = await freshDb();
      final second = QueueCacheDatabase(
        DownloadDatabase(serverId: 'server-2'),
      );
      final mine = cachedFile('a');
      final theirs = cachedFile('b');
      await first.insert(song('a'), file: mine);
      await second.insert(song('b'), file: theirs);

      expect(await first.allFilePaths(), {mine.path, theirs.path});
    });
  });

  group('downloads.db v5 -> v6 migration', () {
    test('- adds the QueueCache table', () async {
      await deleteDb();
      final dir = await getDatabasesPath();
      final legacy = await databaseFactory.openDatabase(
        join(dir, 'downloads.db'),
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, version) async {},
        ),
      );
      await legacy.close();

      final database = QueueCacheDatabase(
        DownloadDatabase(serverId: 'server-1'),
      );
      await database.insert(song('a'), file: cachedFile('a'));

      expect(await database.cachedIds(), {'a'});
    });
  });
}
