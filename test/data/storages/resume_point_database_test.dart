import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/resume_point_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final now = DateTime.utc(2026, 11, 9, 12);

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('resume_points_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
  });

  Future<void> deleteDb() async {
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
  }

  setUp(deleteDb);
  tearDown(deleteDb);

  ResumePointDatabase pointsFor({
    String serverId = 'server-1',
    String? userId = 'user-1',
  }) => ResumePointDatabase(
    DownloadDatabase(serverId: serverId),
    userId: userId,
  );

  ResumePoint point(
    String id, {
    ItemKind kind = ItemKind.album,
    int songIndex = 3,
    Duration position = const Duration(minutes: 1),
    int daysAgo = 0,
  }) => (
    item: LibraryItem(
      id: id,
      name: 'Set $id',
      kind: kind,
      images: const ImageRefs(primary: 'tag'),
      userData: const PlaybackUserData(isFavorite: true),
    ),
    songId: 'song-$songIndex',
    songName: 'Song $songIndex',
    songIndex: songIndex,
    songCount: 12,
    position: position,
    updatedAt: now.subtract(Duration(days: daysAgo)),
  );

  test('- round-trips a point without the like state', () async {
    final points = pointsFor();
    await points.save(point('a', kind: ItemKind.playlist));

    final stored = await points.get('a');

    expect(stored, isNotNull);
    expect(stored!.item.id, 'a');
    expect(stored.item.kind, ItemKind.playlist);
    expect(stored.item.images.primary, 'tag');
    expect(stored.item.userData.isFavorite, isFalse);
    expect(stored.songId, 'song-3');
    expect(stored.songName, 'Song 3');
    expect(stored.songIndex, 3);
    expect(stored.songCount, 12);
    expect(stored.position, const Duration(minutes: 1));
    expect(stored.updatedAt, now);
  });

  test('- saving again replaces the row', () async {
    final points = pointsFor();
    await points.save(point('a', songIndex: 2, daysAgo: 1));
    await points.save(point('a', songIndex: 5));

    final stored = await points.get('a');

    expect(stored!.songIndex, 5);
    expect(stored.updatedAt, now);
    expect(await points.recent(), hasLength(1));
  });

  test('- a point at the start of the first song is not offered', () async {
    final points = pointsFor();
    await points.save(
      point('fresh', songIndex: 0, position: const Duration(seconds: 10)),
    );
    await points.save(
      point('into', songIndex: 0, position: const Duration(seconds: 30)),
    );
    await points.save(point('later', songIndex: 1, position: Duration.zero));

    expect(await points.get('fresh'), isNull);
    expect((await points.get('into'))?.item.id, 'into');
    expect((await points.get('later'))?.item.id, 'later');
    expect(
      (await points.recent()).map((p) => p.item.id),
      unorderedEquals(['later', 'into']),
    );
  });

  test('- recent lists newest first within the age window', () async {
    final points = pointsFor();
    await points.save(point('old', daysAgo: 61));
    await points.save(point('week', daysAgo: 7));
    await points.save(point('today'));

    final window = await points.recent(
      maxAge: const Duration(days: 60),
      now: () => now,
    );
    final all = await points.recent();

    expect(window.map((p) => p.item.id), ['today', 'week']);
    expect(all.map((p) => p.item.id), ['today', 'week', 'old']);
    expect(
      await points.get('old', maxAge: const Duration(days: 60), now: () => now),
      isNull,
    );
  });

  test('- recent honours the limit', () async {
    final points = pointsFor();
    for (var i = 0; i < 5; i++) {
      await points.save(point('$i', daysAgo: i));
    }

    expect(
      (await points.recent(limit: 2)).map((p) => p.item.id),
      ['0', '1'],
    );
  });

  test('- delete removes only that source', () async {
    final points = pointsFor();
    await points.save(point('a'));
    await points.save(point('b'));

    await points.delete('a');

    expect(await points.get('a'), isNull);
    expect((await points.recent()).map((p) => p.item.id), ['b']);
  });

  test('- points are scoped to server and user', () async {
    await pointsFor().save(point('mine'));
    await pointsFor(userId: 'user-2').save(point('theirs'));
    await pointsFor(serverId: 'server-2').save(point('elsewhere'));

    expect((await pointsFor().recent()).map((p) => p.item.id), ['mine']);
    expect(
      (await pointsFor(userId: 'user-2').recent()).map((p) => p.item.id),
      ['theirs'],
    );
    expect(await pointsFor().get('theirs'), isNull);
  });

  test('- without a user nothing is stored or read', () async {
    final anonymous = pointsFor(userId: null);
    await anonymous.save(point('a'));

    expect(await anonymous.recent(), isEmpty);
    expect(await anonymous.get('a'), isNull);
    expect(await pointsFor().recent(), isEmpty);
  });

  test('- deleteAll clears the server, leaving other servers', () async {
    await pointsFor().save(point('a'));
    await pointsFor(userId: 'user-2').save(point('b'));
    await pointsFor(serverId: 'server-2').save(point('c'));

    await pointsFor().deleteAll();

    expect(await pointsFor().recent(), isEmpty);
    expect(await pointsFor(userId: 'user-2').recent(), isEmpty);
    expect(
      (await pointsFor(serverId: 'server-2').recent()).map((p) => p.item.id),
      ['c'],
    );
  });
}
