import 'dart:convert';
import 'dart:io';

import 'package:faker_dart/faker_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/generated_playlist_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final faker = Faker.instance;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('generated_mixes_db');
    await databaseFactory.setDatabasesPath(tempDir.path);
  });

  const userId = 'user-1';
  const libraryId = 'library-1';
  const today = '2026-08-20';

  LibraryItem song(String id, {String? albumId}) => LibraryItem(
    id: id,
    name: faker.lorem.word(),
    kind: ItemKind.song,
    albumId: albumId,
  );

  GeneratedPlaylist playlist(
    String id, {
    List<LibraryItem> covers = const [],
  }) => GeneratedPlaylist(
    item: LibraryItem(id: id, name: '$id mix', kind: ItemKind.playlist),
    coverSongs: covers,
  );

  Future<GeneratedPlaylistDatabase> freshDb() async {
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
    return GeneratedPlaylistDatabase(DownloadDatabase());
  }

  group('generatedPlaylistDayKey', () {
    test('pads month and day', () {
      expect(generatedPlaylistDayKey(DateTime(2026, 1, 2)), '2026-01-02');
      expect(generatedPlaylistDayKey(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('downloads.db v2 -> v3 migration', () {
    Future<void> seedV2Database() async {
      final dir = await getDatabasesPath();
      final legacyDb = await databaseFactory.openDatabase(
        join(dir, 'downloads.db'),
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
CREATE TABLE Downloads (
    Id TEXT PRIMARY KEY,
    AlbumId TEXT,
    FilePath TEXT NOT NULL,
    SizeInBytes INTEGER NOT NULL,
    DownloadDate INTEGER NOT NULL,
    Data TEXT NOT NULL
)''');
            await db.execute('''
CREATE TABLE Albums (
    Id TEXT PRIMARY KEY,
    SizeInBytes INTEGER NOT NULL,
    DownloadDate INTEGER NOT NULL,
    Data TEXT NOT NULL
)''');
          },
        ),
      );
      await legacyDb.insert('Downloads', {
        'Id': 'downloaded-1',
        'AlbumId': 'album-1',
        'FilePath': '/tmp/downloaded-1.flac',
        'SizeInBytes': 100,
        'DownloadDate': 1700000000000,
        'Data': jsonEncode(song('downloaded-1', albumId: 'album-1').toJson()),
      });
      await legacyDb.close();
    }

    test('adds the mix tables and keeps existing downloads', () async {
      final dir = await getDatabasesPath();
      await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
      await seedV2Database();

      final downloads = DownloadDatabase();
      final db = GeneratedPlaylistDatabase(downloads);

      await db.savePlaylists(
        [playlist('mix-a')],
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      expect(
        (await db.getPlaylists(
          userId: userId,
          libraryId: libraryId,
          dayKey: today,
        )).single.item.id,
        'mix-a',
      );
      expect(
        (await downloads.getDownloadedSongs()).single.item.id,
        'downloaded-1',
      );
    });
  });

  group('GeneratedPlaylistDatabase', () {
    test('round-trips playlists in generation order', () async {
      final db = await freshDb();
      final covers = [song('s1', albumId: 'a1'), song('s2', albumId: 'a2')];

      await db.savePlaylists(
        [playlist('mix-a', covers: covers), playlist('mix-b')],
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      final stored = await db.getPlaylists(
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      expect(stored.map((p) => p.item.id), ['mix-a', 'mix-b']);
      expect(stored.first.coverSongs.map((s) => s.id), ['s1', 's2']);
      expect(stored.first.isSynced, isFalse);
    });

    test('scopes rows by user, library and day', () async {
      final db = await freshDb();
      await db.savePlaylists(
        [playlist('mix-a')],
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      expect(
        await db.getPlaylists(
          userId: 'other-user',
          libraryId: libraryId,
          dayKey: today,
        ),
        isEmpty,
      );
      expect(
        await db.getPlaylists(
          userId: userId,
          libraryId: 'other-library',
          dayKey: today,
        ),
        isEmpty,
      );
      expect(
        await db.getPlaylists(
          userId: userId,
          libraryId: libraryId,
          dayKey: '2026-08-19',
        ),
        isEmpty,
      );
    });

    test('a null library id is its own scope', () async {
      final db = await freshDb();
      await db.savePlaylists(
        [playlist('mix-all')],
        userId: userId,
        dayKey: today,
      );

      expect(
        (await db.getPlaylists(userId: userId, dayKey: today)).single.item.id,
        'mix-all',
      );
      expect(
        await db.getPlaylists(
          userId: userId,
          libraryId: libraryId,
          dayKey: today,
        ),
        isEmpty,
      );
    });

    test('saving a new set replaces the day and drops its songs', () async {
      final db = await freshDb();
      await db.savePlaylists(
        [playlist('mix-a')],
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );
      await db.saveSongs(
        [song('s1')],
        playlistId: 'mix-a',
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      await db.savePlaylists(
        [playlist('mix-c')],
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      expect(
        (await db.getPlaylists(
          userId: userId,
          libraryId: libraryId,
          dayKey: today,
        )).map((p) => p.item.id),
        ['mix-c'],
      );
      expect(
        await db.getSongs(
          playlistId: 'mix-a',
          userId: userId,
          libraryId: libraryId,
          dayKey: today,
        ),
        isEmpty,
      );
    });

    test('songs keep their frozen order', () async {
      final db = await freshDb();
      final songs = [song('s3'), song('s1'), song('s2')];

      await db.saveSongs(
        songs,
        playlistId: 'mix-a',
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      final stored = await db.getSongs(
        playlistId: 'mix-a',
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );
      expect(stored.map((s) => s.id), ['s3', 's1', 's2']);
    });

    test('updateSong rewrites one row in place', () async {
      final db = await freshDb();
      await db.saveSongs(
        [song('s1'), song('s2')],
        playlistId: 'mix-a',
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      final updated = song('s2').copyWith(
        userData: const PlaybackUserData(isFavorite: true),
      );
      final rows = await db.updateSong(
        updated,
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      final stored = await db.getSongs(
        playlistId: 'mix-a',
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );
      expect(rows, 1);
      expect(stored.map((s) => s.id), ['s1', 's2']);
      expect(stored.last.userData.isFavorite, isTrue);
      expect(stored.first.userData.isFavorite, isFalse);
    });

    test('markSynced records the remote id', () async {
      final db = await freshDb();
      await db.savePlaylists(
        [playlist('mix-a')],
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      await db.markSynced(
        playlistId: 'mix-a',
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
        remoteId: 'jf-123',
      );

      final stored = (await db.getPlaylists(
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      )).single;
      expect(stored.remoteId, 'jf-123');
      expect(stored.syncedAt, isNotNull);
      expect(stored.isSynced, isTrue);
    });

    test('getUnsynced skips already synced playlists', () async {
      final db = await freshDb();
      await db.savePlaylists(
        [playlist('mix-a'), playlist('mix-b')],
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );
      await db.markSynced(
        playlistId: 'mix-a',
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
        remoteId: 'jf-123',
      );

      final unsynced = await db.getUnsynced(
        userId: userId,
        libraryId: libraryId,
      );
      expect(unsynced.map((row) => row.playlist.item.id), ['mix-b']);
      expect(unsynced.single.dayKey, today);
    });

    test('keeps recent days and prunes beyond the retention window', () async {
      final db = await freshDb();
      final now = DateTime(2026, 8, 20);
      final recent = generatedPlaylistDayKey(
        now.subtract(const Duration(days: generatedPlaylistRetentionDays - 1)),
      );
      final stale = generatedPlaylistDayKey(
        now.subtract(const Duration(days: generatedPlaylistRetentionDays + 1)),
      );

      for (final dayKey in [stale, recent]) {
        await db.savePlaylists(
          [playlist('mix-$dayKey')],
          userId: userId,
          libraryId: libraryId,
          dayKey: dayKey,
        );
        await db.saveSongs(
          [song('s-$dayKey')],
          playlistId: 'mix-$dayKey',
          userId: userId,
          libraryId: libraryId,
          dayKey: dayKey,
        );
      }

      await db.savePlaylists(
        [playlist('mix-today')],
        userId: userId,
        libraryId: libraryId,
        dayKey: today,
      );

      expect(
        await db.getPlaylists(
          userId: userId,
          libraryId: libraryId,
          dayKey: stale,
        ),
        isEmpty,
      );
      expect(
        await db.getSongs(
          playlistId: 'mix-$stale',
          userId: userId,
          libraryId: libraryId,
          dayKey: stale,
        ),
        isEmpty,
      );
      expect(
        (await db.getPlaylists(
          userId: userId,
          libraryId: libraryId,
          dayKey: recent,
        )).single.item.id,
        'mix-$recent',
      );
    });
  });
}
