import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/storages/catalog_cache_database.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  var now = DateTime.utc(2026, 10, 28);

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('catalog_cache_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
  });

  Future<void> deleteDb() async {
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
  }

  setUp(() async {
    now = DateTime.utc(2026, 10, 28);
    await deleteDb();
  });
  tearDown(deleteDb);

  CatalogCacheDatabase storeFor({String serverId = 'server-1'}) =>
      CatalogCacheDatabase(
        DownloadDatabase(serverId: serverId),
        now: () => now,
      );

  group('entries', () {
    test('round-trip with their expiry and survive a reopen', () async {
      final expires = now.add(const Duration(days: 3));
      await storeFor().write('deezer', 'albums/1', '[1]', expires: expires);

      final entry = await storeFor().read('deezer', 'albums/1');

      expect(entry?.json, '[1]');
      expect(entry?.expires, expires);
      expect(entry?.fetchedAt, now);
      expect(await storeFor().read('other', 'albums/1'), isNull);
    });

    test('are shared across servers', () async {
      await storeFor(
        serverId: 'a',
      ).write(
        'deezer',
        'artist/1',
        '{}',
        expires: now.add(const Duration(days: 1)),
      );

      expect(
        await storeFor(serverId: 'b').read('deezer', 'artist/1'),
        isNotNull,
      );
    });

    test('prune drops expired rows, then the oldest over budget', () async {
      final store = storeFor();
      await store.write(
        'deezer',
        'old',
        'x' * 10,
        expires: now.add(const Duration(hours: 1)),
      );
      now = now.add(const Duration(hours: 2));
      await store.write(
        'deezer',
        'early',
        'x' * 10,
        expires: now.add(const Duration(days: 1)),
      );
      now = now.add(const Duration(minutes: 1));
      await store.write(
        'deezer',
        'late',
        'x' * 10,
        expires: now.add(const Duration(days: 1)),
      );

      await store.prune(budgetBytes: 15);

      expect(await store.read('deezer', 'old'), isNull);
      expect(await store.read('deezer', 'early'), isNull);
      expect(await store.read('deezer', 'late'), isNotNull);
    });

    test('clear removes one source or everything', () async {
      final store = storeFor();
      final expires = now.add(const Duration(days: 1));
      await store.write('deezer', 'k', '{}', expires: expires);
      await store.write('other', 'k', '{}', expires: expires);
      await store.saveArtistLink('artist-1', 'deezer', catalogId: '27');

      await store.clear(source: 'deezer');

      expect(await store.read('deezer', 'k'), isNull);
      expect(await store.read('other', 'k'), isNotNull);
      expect(await store.artistLink('artist-1', 'deezer'), isNull);
    });
  });

  group('artist links', () {
    test('remember a match and a miss per server', () async {
      final store = storeFor();
      await store.saveArtistLink('artist-1', 'deezer', catalogId: '27');
      await store.saveArtistLink('artist-2', 'deezer', catalogId: null);

      final match = await store.artistLink('artist-1', 'deezer');
      final miss = await store.artistLink('artist-2', 'deezer');

      expect(match?.catalogId, '27');
      expect(miss, isNotNull);
      expect(miss?.catalogId, isNull);
      expect(miss?.checkedAt, now);
      expect(
        await storeFor(serverId: 'b').artistLink('artist-1', 'deezer'),
        isNull,
      );
    });
  });
}
