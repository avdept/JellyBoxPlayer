import 'dart:convert';
import 'dart:io';

import 'package:faker_dart/faker_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path/path.dart' hide equals;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _legacyDownloadsSql = '''
CREATE TABLE Downloads (
    Id TEXT PRIMARY KEY,
    RunTimeTicks INTEGER NOT NULL,
    IndexNumber INTEGER NOT NULL,
    Type TEXT NOT NULL,
    AlbumArtist TEXT,
    PlaylistItemId TEXT,
    Album TEXT,
    AlbumId TEXT,
    Name TEXT,
    UserData TEXT NOT NULL,
    ImageTags TEXT,
    DownloadDate INTEGER NOT NULL,
    FilePath TEXT NOT NULL,
    SizeInBytes INTEGER NOT NULL
)
''';

const _legacyAlbumsSql = '''
CREATE TABLE Albums (
    Id TEXT PRIMARY KEY,
    Name TEXT NOT NULL,
    Type TEXT NOT NULL,
    Overview TEXT,
    RunTimeTicks INTEGER,
    ProductionYear INTEGER,
    AlbumArtist TEXT,
    ImageTags TEXT,
    BackdropImageTags TEXT,
    DownloadDate INTEGER NOT NULL,
    SizeInBytes INTEGER NOT NULL
)
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final faker = Faker.instance;
  late String dbPath;
  late File songFile;
  late Directory tempDir;

  Future<void> deleteDb() async {
    final dir = await getDatabasesPath();
    dbPath = join(dir, 'downloads.db');
    await databaseFactory.deleteDatabase(dbPath);
  }

  setUp(() async {
    await deleteDb();
    tempDir = await Directory.systemTemp.createTemp('download_database_test');
    songFile = File(join(tempDir.path, 'song.flac'))
      ..writeAsBytesSync(List.generate(1024, (i) => i % 256));
  });

  tearDown(() async {
    await deleteDb();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  LibraryItem buildSong({String? albumId}) => LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    kind: ItemKind.song,
    indexNumber: faker.datatype.number(min: 1, max: 20),
    albumId: albumId ?? faker.datatype.uuid(),
    albumName: faker.lorem.sentence(),
    albumArtist: faker.name.fullName(),
    userData: PlaybackUserData(
      position: Duration(milliseconds: faker.datatype.number()),
      playCount: faker.datatype.number(),
      isFavorite: faker.datatype.boolean(),
      played: faker.datatype.boolean(),
    ),
  );

  LibraryItem buildAlbum() => LibraryItem(
    id: faker.datatype.uuid(),
    name: faker.lorem.sentence(),
    kind: ItemKind.album,
    productionYear: faker.date.past(DateTime.now()).year,
    albumArtist: faker.name.fullName(),
    overview: faker.lorem.sentence(),
    images: ImageRefs(
      primary: faker.datatype.uuid(),
      backdrops: [faker.datatype.uuid(), faker.datatype.uuid()],
    ),
  );

  group('DownloadDatabase (server scoping)', () {
    test('- hides another server\'s downloads', () async {
      final jellyfin = DownloadDatabase(serverId: 'server-a');
      final emby = DownloadDatabase(serverId: 'server-b');
      final song = buildSong();

      await jellyfin.insertDownloadedSong(song, file: songFile);

      expect(await jellyfin.getDownloadedSongs(), hasLength(1));
      expect(await emby.getDownloadedSongs(), isEmpty);
      expect(await emby.isSongDownloaded(song.id), isFalse);
      expect(await emby.getDownloadedSongPath(song.id), isNull);
    });

    test('- hides another server\'s albums', () async {
      final jellyfin = DownloadDatabase(serverId: 'server-a');
      final emby = DownloadDatabase(serverId: 'server-b');
      final album = buildAlbum();

      await jellyfin.insertDownloadedAlbum(album, files: [songFile]);

      expect(await jellyfin.getDownloadedAlbums(), hasLength(1));
      expect(await emby.getDownloadedAlbums(), isEmpty);
      expect(await emby.isAlbumDownloaded(album.id), isFalse);
    });

    test('- does not delete another server\'s rows', () async {
      final jellyfin = DownloadDatabase(serverId: 'server-a');
      final emby = DownloadDatabase(serverId: 'server-b');
      final song = buildSong();

      await jellyfin.insertDownloadedSong(song, file: songFile);
      await emby.deleteDownloadedSong(song.id);

      expect(await jellyfin.getDownloadedSongs(), hasLength(1));
    });

    test('- adopts rows written before scoping existed', () async {
      final legacy = DownloadDatabase();
      final song = buildSong();
      final album = buildAlbum();

      await legacy.insertDownloadedSong(song, file: songFile);
      await legacy.insertDownloadedAlbum(album, files: [songFile]);

      final scoped = DownloadDatabase(serverId: 'server-a');
      expect(await scoped.getDownloadedSongs(), isEmpty);

      await scoped.adoptLegacyDownloads();

      expect(await scoped.getDownloadedSongs(), hasLength(1));
      expect(await scoped.getDownloadedAlbums(), hasLength(1));
      expect(
        await DownloadDatabase(serverId: 'server-b').getDownloadedSongs(),
        isEmpty,
      );
    });

    test('- adoption is a no-op without a server id', () async {
      final legacy = DownloadDatabase();
      await legacy.insertDownloadedSong(buildSong(), file: songFile);

      await legacy.adoptLegacyDownloads();

      expect(await legacy.getDownloadedSongs(), hasLength(1));
      expect(
        await DownloadDatabase(serverId: 'server-a').getDownloadedSongs(),
        isEmpty,
      );
    });
  });

  group('DownloadDatabase (fresh install)', () {
    test('- inserts and reads back a downloaded song', () async {
      final db = DownloadDatabase();
      final song = buildSong();

      await db.insertDownloadedSong(song, file: songFile);
      final songs = await db.getDownloadedSongs();

      expect(songs, hasLength(1));
      expect(songs.single.item, equals(song));
      expect(songs.single.filePath, songFile.path);
      expect(songs.single.sizeInBytes, songFile.lengthSync());
    });

    test('- filters downloaded songs by album id', () async {
      final db = DownloadDatabase();
      final albumId = faker.datatype.uuid();
      final matching = buildSong(albumId: albumId);
      final other = buildSong();

      await db.insertDownloadedSong(matching, file: songFile);
      await db.insertDownloadedSong(other, file: songFile);
      final songs = await db.getDownloadedSongs(albumId);

      expect(songs, hasLength(1));
      expect(songs.single.item.id, matching.id);
    });

    test('- inserts and reads back a downloaded album', () async {
      final db = DownloadDatabase();
      final album = buildAlbum();

      await db.insertDownloadedAlbum(album, files: [songFile]);
      final albums = await db.getDownloadedAlbums();

      expect(albums, hasLength(1));
      expect(albums.single.item, equals(album));
      expect(albums.single.sizeInBytes, songFile.lengthSync());
    });

    test('- reports whether a song or album is downloaded', () async {
      final db = DownloadDatabase();
      final song = buildSong();
      final album = buildAlbum();

      expect(await db.isSongDownloaded(song.id), isFalse);
      expect(await db.isAlbumDownloaded(album.id), isFalse);

      await db.insertDownloadedSong(song, file: songFile);
      await db.insertDownloadedAlbum(album, files: [songFile]);

      expect(await db.isSongDownloaded(song.id), isTrue);
      expect(await db.isAlbumDownloaded(album.id), isTrue);
    });

    test('- deletes a downloaded song and its file', () async {
      final db = DownloadDatabase();
      final song = buildSong();
      await db.insertDownloadedSong(song, file: songFile);

      await db.deleteDownloadedSong(song.id);

      expect(await db.getDownloadedSongs(), isEmpty);
      expect(songFile.existsSync(), isFalse);
    });

    test('- deletes a downloaded album and its songs', () async {
      final db = DownloadDatabase();
      final album = buildAlbum();
      final song = buildSong(albumId: album.id);
      await db.insertDownloadedAlbum(album, files: [songFile]);
      await db.insertDownloadedSong(song, file: songFile);

      await db.deleteDownloadedAlbum(album.id);

      expect(await db.getDownloadedAlbums(), isEmpty);
      expect(await db.getDownloadedSongs(album.id), isEmpty);
    });
  });

  group('DownloadDatabase (v1 -> v2 migration)', () {
    Future<void> seedLegacyDatabase({
      required Map<String, Object?> songRow,
      required Map<String, Object?> albumRow,
    }) async {
      final legacyDb = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(_legacyDownloadsSql);
            await db.execute(_legacyAlbumsSql);
          },
        ),
      );
      await legacyDb.insert('Downloads', songRow);
      await legacyDb.insert('Albums', albumRow);
      await legacyDb.close();
    }

    test('- migrates legacy song rows to the new blob schema', () async {
      final songId = faker.datatype.uuid();
      final albumId = faker.datatype.uuid();
      await seedLegacyDatabase(
        songRow: {
          'Id': songId,
          'RunTimeTicks': 2400000000,
          'IndexNumber': 3,
          'Type': 'Audio',
          'AlbumArtist': 'Legacy Artist',
          'PlaylistItemId': null,
          'Album': 'Legacy Album',
          'AlbumId': albumId,
          'Name': 'Legacy Song',
          'UserData': jsonEncode({
            'PlaybackPositionTicks': 1200000000,
            'PlayCount': 4,
            'IsFavorite': true,
            'Played': true,
          }),
          'ImageTags': 'Primary:legacy-tag',
          'DownloadDate': 1700000000000,
          'FilePath': songFile.path,
          'SizeInBytes': 12345,
        },
        albumRow: {
          'Id': albumId,
          'Name': 'Legacy Album',
          'Type': 'MusicAlbum',
          'Overview': 'A legacy album',
          'RunTimeTicks': 24000000000,
          'ProductionYear': 1999,
          'AlbumArtist': 'Legacy Artist',
          'ImageTags': 'Primary:legacy-album-tag',
          'BackdropImageTags': 'backdrop1,backdrop2',
          'DownloadDate': 1700000000000,
          'SizeInBytes': 54321,
        },
      );

      final db = DownloadDatabase();
      final songs = await db.getDownloadedSongs();
      final albums = await db.getDownloadedAlbums();

      expect(songs, hasLength(1));
      final song = songs.single;
      expect(song.item.id, songId);
      expect(song.item.name, 'Legacy Song');
      expect(song.item.kind, ItemKind.song);
      expect(song.item.indexNumber, 3);
      expect(song.item.duration, const Duration(minutes: 4));
      expect(song.item.albumId, albumId);
      expect(song.item.albumName, 'Legacy Album');
      expect(song.item.albumArtist, 'Legacy Artist');
      expect(song.item.images.primary, 'legacy-tag');
      expect(song.item.userData.position, const Duration(minutes: 2));
      expect(song.item.userData.playCount, 4);
      expect(song.item.userData.isFavorite, isTrue);
      expect(song.item.userData.played, isTrue);
      expect(song.filePath, songFile.path);
      expect(song.sizeInBytes, 12345);

      expect(albums, hasLength(1));
      final album = albums.single;
      expect(album.item.id, albumId);
      expect(album.item.name, 'Legacy Album');
      expect(album.item.kind, ItemKind.album);
      expect(album.item.overview, 'A legacy album');
      expect(album.item.productionYear, 1999);
      expect(album.item.albumArtist, 'Legacy Artist');
      expect(album.item.images.primary, 'legacy-album-tag');
      expect(album.item.images.backdrops, ['backdrop1', 'backdrop2']);
      expect(album.sizeInBytes, 54321);
    });

    test('- preserves existing rows so no re-download is required', () async {
      final songId = faker.datatype.uuid();
      final albumId = faker.datatype.uuid();
      await seedLegacyDatabase(
        songRow: {
          'Id': songId,
          'RunTimeTicks': 0,
          'IndexNumber': 1,
          'Type': 'Audio',
          'AlbumArtist': null,
          'PlaylistItemId': null,
          'Album': null,
          'AlbumId': albumId,
          'Name': 'Another Song',
          'UserData': jsonEncode(<String, dynamic>{}),
          'ImageTags': null,
          'DownloadDate': 1700000000000,
          'FilePath': songFile.path,
          'SizeInBytes': 999,
        },
        albumRow: {
          'Id': albumId,
          'Name': 'Another Album',
          'Type': 'MusicAlbum',
          'Overview': null,
          'RunTimeTicks': null,
          'ProductionYear': null,
          'AlbumArtist': null,
          'ImageTags': null,
          'BackdropImageTags': null,
          'DownloadDate': 1700000000000,
          'SizeInBytes': 999,
        },
      );

      final db = DownloadDatabase();
      expect(await db.isSongDownloaded(songId), isTrue);
      expect(await db.isAlbumDownloaded(albumId), isTrue);
      expect(await db.getDownloadedSongPath(songId), songFile.path);
    });
  });
}
