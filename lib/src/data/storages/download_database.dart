import 'dart:convert';
import 'dart:io' show File;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DownloadDatabase {
  DownloadDatabase({
    this.serverId = '',
    @visibleForTesting Database? db,
  }) : _db = db;

  static const _schemaVersion = 4;

  final String serverId;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB('downloads.db');
    return _db!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, filePath),
      version: _schemaVersion,
      onCreate: (db, version) => _createDB(db),
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db) async {
    final sqlFiles = {
      DbMigrations.downloadsV2,
      DbMigrations.albumsV2,
      DbMigrations.generatedPlaylists,
      DbMigrations.generatedPlaylistItems,
    };
    final queries = await Future.wait(sqlFiles.map(rootBundle.loadString));
    await Future.wait(queries.map(db.execute));
    await _migrateToV4(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _migrateToV2(db);
    if (oldVersion < 3) await _migrateToV3(db);
    if (oldVersion < 4) await _migrateToV4(db);
  }

  Future<void> _migrateToV4(Database db) async {
    final createV4 = [DbMigrations.downloadsV4, DbMigrations.albumsV4];
    final queries = await Future.wait(createV4.map(rootBundle.loadString));
    for (final query in queries) {
      await db.execute(query);
    }
  }

  // TODO: Remove in 2.5.0, tis is one time thing to adopt dowmloads without serverId
  Future<void> adoptLegacyDownloads() async {
    if (serverId.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final table in const ['Downloads', 'Albums']) {
      batch.update(
        table,
        {'ServerId': serverId},
        where: 'ServerId = ?',
        whereArgs: [''],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _migrateToV3(Database db) async {
    final createV3 = {
      DbMigrations.generatedPlaylists,
      DbMigrations.generatedPlaylistItems,
    };
    final queries = await Future.wait(createV3.map(rootBundle.loadString));
    await Future.wait(queries.map(db.execute));
  }

  Future<void> _migrateToV2(Database db) async {
    final legacySongs = await db.query('Downloads');
    final legacyAlbums = await db.query('Albums');

    await db.execute('ALTER TABLE Downloads RENAME TO DownloadsV1');
    await db.execute('ALTER TABLE Albums RENAME TO AlbumsV1');

    final createV2 = {DbMigrations.downloadsV2, DbMigrations.albumsV2};
    final createQueries = await Future.wait(
      createV2.map(rootBundle.loadString),
    );
    await Future.wait(createQueries.map(db.execute));

    final batch = db.batch();
    for (final row in legacySongs) {
      batch.insert('Downloads', {
        'Id': row['Id'],
        'AlbumId': row['AlbumId'],
        'FilePath': row['FilePath'],
        'SizeInBytes': row['SizeInBytes'],
        'DownloadDate': row['DownloadDate'],
        'Data': jsonEncode(_legacySongToLibraryItem(row).toJson()),
      });
    }
    for (final row in legacyAlbums) {
      batch.insert('Albums', {
        'Id': row['Id'],
        'SizeInBytes': row['SizeInBytes'],
        'DownloadDate': row['DownloadDate'],
        'Data': jsonEncode(_legacyAlbumToLibraryItem(row).toJson()),
      });
    }
    await batch.commit(noResult: true);

    await db.execute('DROP TABLE DownloadsV1');
    await db.execute('DROP TABLE AlbumsV1');
  }

  Future<int> insertDownloadedSong(
    LibraryItem song, {
    required File file,
  }) async {
    final db = await database;
    return db.insert('Downloads', {
      'Id': song.id,
      'ServerId': serverId,
      'AlbumId': song.albumId,
      'FilePath': file.path,
      'SizeInBytes': file.lengthSync(),
      'DownloadDate': DateTime.now().millisecondsSinceEpoch,
      'Data': jsonEncode(song.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertDownloadedAlbum(
    LibraryItem album, {
    required List<File> files,
  }) async {
    final db = await database;
    return db.insert('Albums', {
      'Id': album.id,
      'ServerId': serverId,
      'SizeInBytes': files.map((e) => e.lengthSync()).sum,
      'DownloadDate': DateTime.now().millisecondsSinceEpoch,
      'Data': jsonEncode(album.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DownloadedSong>> getDownloadedSongs([
    String? albumId,
  ]) async {
    final db = await database;
    final results = (albumId == null)
        ? await db.query(
            'Downloads',
            where: 'ServerId = ?',
            whereArgs: [serverId],
          )
        : await db.query(
            'Downloads',
            where: 'AlbumId = ? AND ServerId = ?',
            whereArgs: [albumId, serverId],
          );
    return results.map(_downloadedSongFromRow).toList();
  }

  Future<List<DownloadedAlbum>> getDownloadedAlbums() async {
    final db = await database;
    final results = await db.query(
      'Albums',
      where: 'ServerId = ?',
      whereArgs: [serverId],
    );
    return results.map(_downloadedAlbumFromRow).toList();
  }

  Future<int> deleteDownloadedSong(String id) async {
    final db = await database;
    final filePath = await getDownloadedSongPath(id);

    if (filePath != null) {
      // Delete file
      final file = File(filePath);
      if (file.existsSync()) await file.delete();
    }

    return db.delete(
      'Downloads',
      where: 'Id = ? AND ServerId = ?',
      whereArgs: [id, serverId],
    );
  }

  Future<void> deleteDownloadedAlbum(String albumId) async {
    final db = await database;
    final songs = await getDownloadedSongs(albumId);
    final files = songs.map((song) => File(song.filePath));

    await Future.wait([
      // Delete each song file
      for (final file in files)
        if (file.existsSync()) file.delete(),
    ]);

    final batch = db.batch()
      // Delete the album entry
      ..delete(
        'Albums',
        where: 'Id = ? AND ServerId = ?',
        whereArgs: [albumId, serverId],
      )
      // Delete all songs from this album
      ..delete(
        'Downloads',
        where: 'AlbumId = ? AND ServerId = ?',
        whereArgs: [albumId, serverId],
      );

    await batch.commit();
  }

  Future<bool> isSongDownloaded(String id) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM Downloads WHERE Id = ? AND ServerId = ?',
        [id, serverId],
      ),
    );
    return count! > 0;
  }

  Future<bool> isAlbumDownloaded(String albumId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM Albums WHERE Id = ? AND ServerId = ?',
        [albumId, serverId],
      ),
    );
    return count! > 0;
  }

  Future<String?> getDownloadedSongPath(String id) async {
    final db = await database;
    final results = await db.query(
      'Downloads',
      columns: ['FilePath'],
      where: 'Id = ? AND ServerId = ?',
      whereArgs: [id, serverId],
    );

    return results.firstOrNull?['FilePath'] as String?;
  }
}

DownloadedSong _downloadedSongFromRow(Map<String, Object?> row) =>
    DownloadedSong(
      item: LibraryItem.fromJson(
        jsonDecode(row['Data']! as String) as Map<String, dynamic>,
      ),
      filePath: row['FilePath']! as String,
      sizeInBytes: row['SizeInBytes']! as int,
      downloadDate: DateTime.fromMillisecondsSinceEpoch(
        row['DownloadDate']! as int,
      ),
    );

DownloadedAlbum _downloadedAlbumFromRow(Map<String, Object?> row) =>
    DownloadedAlbum(
      item: LibraryItem.fromJson(
        jsonDecode(row['Data']! as String) as Map<String, dynamic>,
      ),
      sizeInBytes: row['SizeInBytes']! as int,
      downloadDate: DateTime.fromMillisecondsSinceEpoch(
        row['DownloadDate']! as int,
      ),
    );

LibraryItem _legacySongToLibraryItem(Map<String, Object?> row) {
  final userData = row['UserData'] != null
      ? jsonDecode(row['UserData']! as String) as Map<String, dynamic>
      : const <String, dynamic>{};
  return LibraryItem(
    id: row['Id']! as String,
    name: row['Name'] as String? ?? '',
    kind: ItemKind.song,
    indexNumber: row['IndexNumber'] as int? ?? 0,
    duration: _ticksToDuration(row['RunTimeTicks'] as int?),
    albumId: row['AlbumId'] as String?,
    albumName: row['Album'] as String?,
    albumArtist: row['AlbumArtist'] as String?,
    playlistItemId: row['PlaylistItemId'] as String?,
    images: ImageRefs(
      primary: _legacyTagsMap(row['ImageTags'] as String?)['Primary'],
    ),
    userData: PlaybackUserData(
      position: _ticksToDuration(
        (userData['PlaybackPositionTicks'] as num?)?.toInt(),
      ),
      playCount: (userData['PlayCount'] as num?)?.toInt() ?? 0,
      isFavorite: userData['IsFavorite'] as bool? ?? false,
      played: userData['Played'] as bool? ?? false,
    ),
  );
}

LibraryItem _legacyAlbumToLibraryItem(Map<String, Object?> row) => LibraryItem(
  id: row['Id']! as String,
  name: row['Name'] as String? ?? '',
  kind: ItemKind.album,
  duration: _ticksToDuration(row['RunTimeTicks'] as int?),
  overview: row['Overview'] as String?,
  productionYear: row['ProductionYear'] as int?,
  albumArtist: row['AlbumArtist'] as String?,
  images: ImageRefs(
    primary: _legacyTagsMap(row['ImageTags'] as String?)['Primary'],
    backdrops: _legacyTagsList(row['BackdropImageTags'] as String?),
  ),
);

Duration _ticksToDuration(int? ticks) =>
    Duration(milliseconds: ((ticks ?? 0) / 10000).round());

Map<String, String> _legacyTagsMap(String? raw) {
  if (raw == null || raw.isEmpty) return const {};
  final map = <String, String>{};
  for (final tag in raw.split(',')) {
    final parts = tag.split(':');
    if (parts.length < 2) continue;
    map[parts[0]] = parts[1];
  }
  return map;
}

List<String> _legacyTagsList(String? raw) =>
    (raw == null || raw.isEmpty) ? const [] : raw.split(',');
