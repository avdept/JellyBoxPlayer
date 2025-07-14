import 'package:jplayer/src/data/dto/dto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DownloadDatabase {
  const DownloadDatabase._();

  static const instance = DownloadDatabase._();
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB('downloads.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, filePath),
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await Future.wait([
      db.execute('''
        CREATE TABLE downloads (
          id TEXT PRIMARY KEY,
          name TEXT,
          albumId TEXT,
          albumName TEXT,
          artistName TEXT,
          downloadDate INTEGER NOT NULL,
          filePath TEXT NOT NULL,
          sizeInBytes INTEGER NOT NULL
        )
      '''),
      db.execute('''
        CREATE TABLE albums (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          artistName TEXT,
          imageTags TEXT,
          downloadDate INTEGER NOT NULL,
          sizeInBytes INTEGER NOT NULL
        )
      '''),
    ]);
  }

  Future<int> insertDownloadedSong(DownloadedItemDTO item) async {
    final db = await database;
    return db.insert('downloads', item.toJson());
  }

  Future<int> insertDownloadedAlbum(ItemDTO album, int sizeInBytes) async {
    final db = await database;
    return db.insert('albums', {
      'id': album.id,
      'name': album.name,
      'artistName': album.albumArtist,
      'imageTags': album.imageTags.entries
          .map((tag) => '${tag.key}:${tag.value}')
          .join(','),
      'downloadDate': DateTime.now().millisecondsSinceEpoch,
      'sizeInBytes': sizeInBytes,
    });
  }

  Future<List<DownloadedItemDTO>> getDownloadedSongs() async {
    final db = await database;
    final results = await db.query('downloads');
    return results.map(DownloadedItemDTO.fromJson).toList();
  }

  Future<List<DownloadedItemDTO>> getDownloadedSongsByAlbum(
    String albumId,
  ) async {
    final db = await database;
    final results = await db.query(
      'downloads',
      where: 'albumId = ?',
      whereArgs: [albumId],
    );
    return results.map(DownloadedItemDTO.fromJson).toList();
  }

  Future<List<DownloadedAlbumDTO>> getDownloadedAlbums() async {
    final db = await database;
    final results = await db.query('albums');
    return List.from(
      results.map(
        (json) => DownloadedAlbumDTO(
          id: json['id']! as String,
          name: json['name']! as String,
          artistName: json['artistName'] as String?,
          imageTags: (json['imageTags']! as String)
              .split(',')
              .fold<Map<String, String>>(
                {},
                (map, tag) {
                  final parts = tag.split(':');
                  map[parts[0]] = parts[1];
                  return map;
                },
              ),
          downloadDate: DateTime.fromMillisecondsSinceEpoch(
            json['downloadDate']! as int,
          ),
          sizeInBytes: json['sizeInBytes']! as int,
        ),
      ),
    );
  }

  Future<int> deleteDownloadedSong(String id) async {
    final db = await database;
    return db.delete(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDownloadedAlbum(String albumId) async {
    final db = await database;
    final batch =
        db.batch()
          // Delete the album entry
          ..delete(
            'albums',
            where: 'id = ?',
            whereArgs: [albumId],
          )
          // Delete all songs from this album
          ..delete(
            'downloads',
            where: 'albumId = ?',
            whereArgs: [albumId],
          );

    await batch.commit();
  }

  Future<bool> isSongDownloaded(String id) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM downloads WHERE id = ?', [id]),
    );
    return count! > 0;
  }

  Future<bool> isAlbumDownloaded(String albumId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM albums WHERE id = ?', [albumId]),
    );
    return count! > 0;
  }

  Future<String?> getDownloadedSongPath(String id) async {
    final db = await database;
    final results = await db.query(
      'downloads',
      columns: ['filePath'],
      where: 'id = ?',
      whereArgs: [id],
    );

    return results.firstOrNull?['filePath'] as String?;
  }

  Future<void> close() async {
    final db = await database;
    return db.close();
  }
}
