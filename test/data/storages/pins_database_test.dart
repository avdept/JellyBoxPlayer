import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/pins_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final now = DateTime.utc(2026, 11, 3, 12);

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('pins_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
  });

  Future<void> deleteDb() async {
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
  }

  setUp(deleteDb);
  tearDown(deleteDb);

  PinsDatabase pinsFor({
    String serverId = 'server-1',
    String? userId = 'user-1',
  }) => PinsDatabase(DownloadDatabase(serverId: serverId), userId: userId);

  PinnedItem pin(
    String id, {
    ItemKind kind = ItemKind.album,
    Uri? imageUrl,
    int minutesAgo = 0,
  }) => (
    itemId: id,
    kind: kind,
    name: 'Name $id',
    imageUrl: imageUrl,
    pinnedAt: now.subtract(Duration(minutes: minutesAgo)),
  );

  test('- round-trips pins newest first', () async {
    final pins = pinsFor();
    await pins.pin(pin('old', minutesAgo: 10));
    await pins.pin(
      pin(
        'new',
        kind: ItemKind.artist,
        imageUrl: Uri.parse('http://server/Items/new/Images/Primary'),
      ),
    );

    final stored = await pins.getPins();

    expect(stored.map((p) => p.itemId), ['new', 'old']);
    expect(stored.first.kind, ItemKind.artist);
    expect(stored.first.name, 'Name new');
    expect(
      stored.first.imageUrl,
      Uri.parse('http://server/Items/new/Images/Primary'),
    );
    expect(stored.first.pinnedAt, now);
    expect(stored.last.imageUrl, isNull);
  });

  test('- older pins than the longevity are left out', () async {
    final pins = pinsFor();
    await pins.pin(pin('fresh', minutesAgo: 60));
    await pins.pin(pin('stale', minutesAgo: 8 * 24 * 60));

    final week = await pins.getPins(
      maxAge: const Duration(days: 7),
      now: () => now,
    );
    final month = await pins.getPins(
      maxAge: const Duration(days: 30),
      now: () => now,
    );

    expect(week.map((p) => p.itemId), ['fresh']);
    expect(month.map((p) => p.itemId), ['fresh', 'stale']);
  });

  test('- pinning again replaces the row', () async {
    final pins = pinsFor();
    await pins.pin(pin('a', minutesAgo: 5));
    await pins.pin(pin('a'));

    final stored = await pins.getPins();

    expect(stored, hasLength(1));
    expect(stored.single.pinnedAt, now);
  });

  test('- unpin removes only that item', () async {
    final pins = pinsFor();
    await pins.pin(pin('a'));
    await pins.pin(pin('b'));

    await pins.unpin('a');

    expect((await pins.getPins()).map((p) => p.itemId), ['b']);
  });

  test('- pins are scoped to server and user', () async {
    await pinsFor().pin(pin('mine'));
    await pinsFor(userId: 'user-2').pin(pin('theirs'));
    await pinsFor(serverId: 'server-2').pin(pin('elsewhere'));

    expect((await pinsFor().getPins()).map((p) => p.itemId), ['mine']);
    expect(
      (await pinsFor(userId: 'user-2').getPins()).map((p) => p.itemId),
      ['theirs'],
    );
  });

  test('- without a user nothing is stored or read', () async {
    final anonymous = pinsFor(userId: null);
    await anonymous.pin(pin('a'));

    expect(await anonymous.getPins(), isEmpty);
    expect(await pinsFor().getPins(), isEmpty);
  });

  test('- deleteAll clears the server, leaving other servers', () async {
    await pinsFor().pin(pin('a'));
    await pinsFor(userId: 'user-2').pin(pin('b'));
    await pinsFor(serverId: 'server-2').pin(pin('c'));

    await pinsFor().deleteAll();

    expect(await pinsFor().getPins(), isEmpty);
    expect(await pinsFor(userId: 'user-2').getPins(), isEmpty);
    expect(
      (await pinsFor(serverId: 'server-2').getPins()).map((p) => p.itemId),
      ['c'],
    );
  });
}
