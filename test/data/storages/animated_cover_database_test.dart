import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/storages/animated_cover_database.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('animated_cover_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
  });

  Future<AnimatedCoverDatabase> freshDb() async {
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
    return AnimatedCoverDatabase(DownloadDatabase(serverId: 'server-1'));
  }

  group('AnimatedCoverDatabase', () {
    test('- key ignores case and surrounding whitespace', () {
      expect(
        AnimatedCoverDatabase.keyFor(
          artist: ' Gorillaz ',
          album: 'PLASTIC Beach',
        ),
        AnimatedCoverDatabase.keyFor(
          artist: 'gorillaz',
          album: 'plastic beach',
        ),
      );
      expect(
        AnimatedCoverDatabase.keyFor(artist: 'a', album: 'b'),
        isNot(AnimatedCoverDatabase.keyFor(artist: 'b', album: 'a')),
      );
    });

    test('- stores a found url and reads it back', () async {
      final database = await freshDb();
      final url = Uri.parse('https://example.com/cover.m3u8');
      final key = AnimatedCoverDatabase.keyFor(artist: 'x', album: 'y');

      await database.put(key, url);
      final entry = await database.get(key);

      expect(entry?.url, url);
      expect(
        DateTime.now().difference(entry!.checkedAt),
        lessThan(const Duration(seconds: 5)),
      );
    });

    test('- remembers a negative result as an entry without a url', () async {
      final database = await freshDb();
      final key = AnimatedCoverDatabase.keyFor(artist: 'x', album: 'y');

      await database.put(key, null);
      final entry = await database.get(key);

      expect(entry, isNotNull);
      expect(entry!.url, isNull);
      expect(await database.get('other'), isNull);
    });

    test('- a later lookup replaces the earlier one', () async {
      final database = await freshDb();
      final key = AnimatedCoverDatabase.keyFor(artist: 'x', album: 'y');
      final url = Uri.parse('https://example.com/cover.m3u8');

      await database.put(key, null);
      await database.put(key, url);

      expect((await database.get(key))?.url, url);
    });
  });
}
