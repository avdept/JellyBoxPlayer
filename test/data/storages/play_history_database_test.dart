import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/play_history_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final now = DateTime.utc(2026, 10, 21);

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('play_history_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
  });

  Future<void> deleteDb() async {
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
  }

  setUp(deleteDb);
  tearDown(deleteDb);

  PlayHistoryDatabase historyFor({
    String serverId = 'server-1',
    String? userId = 'user-1',
  }) => PlayHistoryDatabase(
    DownloadDatabase(serverId: serverId),
    userId: userId,
  );

  LibraryItem song(String id, {String? name}) => LibraryItem(
    id: id,
    name: name ?? id,
    kind: ItemKind.song,
    albumId: 'album-$id',
    artists: [ArtistRef(id: 'artist-$id', name: 'Artist $id')],
    duration: const Duration(minutes: 3),
    audioSources: const [AudioSourceInfo(container: 'flac', bitRate: 1411000)],
    userData: const PlaybackUserData(isFavorite: true, rating: 4),
  );

  SongPlay play(String songId, {int daysAgo = 1, int minute = 0}) => (
    song: song(songId),
    playedAt: now.subtract(Duration(days: daysAgo, minutes: minute)),
  );

  test(
    '- counts plays per song inside the window, most played first',
    () async {
      final history = historyFor();
      await history.addPlays([
        play('quiet', daysAgo: 3),
        play('loud', daysAgo: 2),
        play('loud', daysAgo: 4, minute: 1),
        play('loud', daysAgo: 35),
        play('outside', daysAgo: 40),
      ]);

      final top = await history.topPlayed(
        window: const Duration(days: 30),
        limit: 10,
        now: () => now,
      );

      expect(
        [for (final row in top) (row.songId, row.playCount)],
        [('loud', 2), ('quiet', 1)],
      );
      expect(top.first.lastPlayed, now.subtract(const Duration(days: 2)));
    },
  );

  test('- songs below the minimum play count are left out', () async {
    final history = historyFor();
    await history.addPlays([
      play('once'),
      play('twice', daysAgo: 2),
      play('twice', daysAgo: 3),
      play('twice-but-old', daysAgo: 4),
      play('twice-but-old', daysAgo: 40),
    ]);

    final top = await history.topPlayed(
      window: const Duration(days: 30),
      limit: 10,
      minPlays: 2,
      now: () => now,
    );

    expect([for (final row in top) row.songId], ['twice']);
  });

  test('- breaks play count ties by most recent play', () async {
    final history = historyFor();
    await history.addPlays([
      play('older', daysAgo: 5),
      play('newer'),
    ]);

    final top = await history.topPlayed(
      window: const Duration(days: 30),
      limit: 10,
      now: () => now,
    );

    expect([for (final row in top) row.songId], ['newer', 'older']);
  });

  test('- the same play recorded twice counts once', () async {
    final history = historyFor();
    await history.addPlays([play('song')]);
    await history.addPlays([play('song')]);

    final top = await history.topPlayed(
      window: const Duration(days: 30),
      limit: 10,
      now: () => now,
    );

    expect(top.single.playCount, 1);
  });

  test('- plays are scoped to their server and user', () async {
    await historyFor().addPlays([play('mine')]);
    await historyFor(userId: 'user-2').addPlays([play('theirs')]);

    final mine = await historyFor().topPlayed(
      window: const Duration(days: 30),
      limit: 10,
      now: () => now,
    );
    final other = await historyFor(serverId: 'server-2').topPlayed(
      window: const Duration(days: 30),
      limit: 10,
      now: () => now,
    );

    expect(mine.single.songId, 'mine');
    expect(other, isEmpty);
  });

  test('- old plays are kept for a wider look back', () async {
    final history = historyFor();
    await history.addPlays([
      play('ancient', daysAgo: 400),
      play('recent'),
    ]);

    final month = await history.topPlayed(
      window: const Duration(days: 30),
      limit: 10,
      now: () => now,
    );
    final years = await history.topPlayed(
      window: const Duration(days: 365 * 2),
      limit: 10,
      now: () => now,
    );

    expect([for (final row in month) row.songId], ['recent']);
    expect([for (final row in years) row.songId], ['recent', 'ancient']);
  });

  test('- counts the distinct songs played inside the window', () async {
    final history = historyFor();
    await history.addPlays([
      play('a', daysAgo: 2),
      play('a', daysAgo: 3),
      play('b', daysAgo: 4),
      play('outside', daysAgo: 40),
    ]);

    final count = await history.trackedSongCount(
      window: const Duration(days: 30),
      now: () => now,
    );
    final repeated = await history.trackedSongCount(
      window: const Duration(days: 30),
      minPlays: 2,
      now: () => now,
    );

    expect(count, 2);
    expect(repeated, 1);
  });

  test(
    '- keeps a snapshot of each played song, without like or rating',
    () async {
      final history = historyFor();
      await history.addPlays([play('song')]);

      final stored = await history.playedSongsByIds(['song']);

      final item = stored['song']!;
      expect(item.name, 'song');
      expect(item.albumId, 'album-song');
      expect(item.artists.single.id, 'artist-song');
      expect(item.duration, const Duration(minutes: 3));
      expect(item.audioSources.single.container, 'flac');
      expect(item.userData.isFavorite, isFalse);
      expect(item.userData.rating, 0);
    },
  );

  test('- a replay refreshes the stored snapshot', () async {
    final history = historyFor();
    await history.addPlays([play('song')]);
    await history.addPlays([
      (song: song('song', name: 'renamed'), playedAt: now),
    ]);

    final stored = await history.playedSongsByIds(['song']);

    expect(stored['song']!.name, 'renamed');
  });

  test(
    '- deleteAll clears the server, without a user it records nothing',
    () async {
      final history = historyFor();
      await history.addPlays([play('song')]);
      await historyFor(userId: null).addPlays([play('ignored')]);
      await history.deleteAll();

      final top = await history.topPlayed(
        window: const Duration(days: 30),
        limit: 10,
        now: () => now,
      );
      final stored = await history.playedSongsByIds(['song', 'ignored']);

      expect(top, isEmpty);
      expect(stored, isEmpty);
    },
  );
}
