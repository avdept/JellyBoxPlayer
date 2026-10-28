import 'dart:convert';
import 'dart:io' show Directory, File, FileSystemException;
import 'dart:math' show min;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DownloadDatabase {
  DownloadDatabase({
    this.serverId = '',
    @visibleForTesting Database? db,
  }) : _db = db;

  static const _schemaVersion = 14;

  static String? databaseDirectory;

  final String serverId;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB('downloads.db');
    return _db!;
  }

  Future<Database> _initDB(String filePath) async {
    final override = databaseDirectory;
    final dbPath = override ?? await getDatabasesPath();
    if (override != null) {
      await Directory(override).create(recursive: true);
      await _adoptLegacyLocation(filePath, override);
    }
    return openDatabase(
      join(dbPath, filePath),
      version: _schemaVersion,
      onCreate: (db, version) => _createDB(db),
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _adoptLegacyLocation(String filePath, String dbPath) async {
    try {
      final target = join(dbPath, filePath);
      if (File(target).existsSync()) return;

      final legacyDir = await getDatabasesPath();
      if (equals(legacyDir, dbPath)) return;
      if (!File(join(legacyDir, filePath)).existsSync()) return;

      for (final suffix in const ['', '-wal', '-shm', '-journal']) {
        final source = File(join(legacyDir, '$filePath$suffix'));
        if (!source.existsSync()) continue;
        try {
          await source.rename('$target$suffix');
        } on FileSystemException {
          await source.copy('$target$suffix');
          await source.delete();
        }
      }
    } on Object {
      return;
    }
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
    await _migrateToV5(db);
    await _migrateToV6(db);
    await _migrateToV7(db);
    await _migrateToV8(db);
    await _migrateToV9(db);
    await _migrateToV10(db);
    await _migrateToV11(db);
    await _migrateToV12(db);
    await _migrateToV13(db);
    await _migrateToV14(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _migrateToV2(db);
    if (oldVersion < 3) await _migrateToV3(db);
    if (oldVersion < 4) await _migrateToV4(db);
    if (oldVersion < 5) await _migrateToV5(db);
    if (oldVersion < 6) await _migrateToV6(db);
    if (oldVersion < 7) await _migrateToV7(db);
    if (oldVersion < 8) await _migrateToV8(db);
    if (oldVersion < 9) await _migrateToV9(db);
    if (oldVersion < 10) await _migrateToV10(db);
    if (oldVersion < 11) await _migrateToV11(db);
    if (oldVersion < 12) await _migrateToV12(db);
    if (oldVersion < 13) await _migrateToV13(db);
    if (oldVersion < 14) await _migrateToV14(db);
  }

  Future<void> _migrateToV14(Database db) async {
    await db.execute(await rootBundle.loadString(DbMigrations.catalogCacheV14));
    await db.execute(
      await rootBundle.loadString(DbMigrations.catalogArtistLinksV14),
    );
  }

  Future<void> _migrateToV13(Database db) async {
    await _relativizeFilePaths(db, 'Downloads', depth: 2);
    await _relativizeFilePaths(db, 'QueueCache', depth: 1);
  }

  Future<void> _relativizeFilePaths(
    Database db,
    String table, {
    required int depth,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.isEmpty) return;
    final rows = await db.query(table, columns: ['rowid', 'FilePath']);
    final batch = db.batch();
    var dirty = false;
    for (final row in rows) {
      final stored = row['FilePath']! as String;
      final relative = StoredFilePath.relativize(stored, depth: depth);
      if (relative == null) continue;
      dirty = true;
      batch.update(
        table,
        {'FilePath': relative},
        where: 'rowid = ?',
        whereArgs: [row['rowid']],
      );
    }
    if (dirty) await batch.commit(noResult: true);
  }

  Future<void> _migrateToV12(Database db) async {
    await db.execute(await rootBundle.loadString(DbMigrations.playedSongsV12));
  }

  Future<void> _migrateToV11(Database db) async {
    await db.execute(await rootBundle.loadString(DbMigrations.songPlaysV11));
  }

  Future<void> _migrateToV10(Database db) async {
    await _addColumn(
      db,
      table: 'Downloads',
      column: 'Pending',
      sql:
          'ALTER TABLE Downloads ADD COLUMN Pending INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _addColumn(
    Database db, {
    required String table,
    required String column,
    required String sql,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.isEmpty) return;
    if (columns.any((existing) => existing['name'] == column)) return;
    await db.execute(sql);
  }

  Future<void> _migrateToV9(Database db) async {
    await db.execute(
      await rootBundle.loadString(DbMigrations.animatedCoversV9),
    );
  }

  Future<void> _migrateToV8(Database db) async {
    await db.execute(await rootBundle.loadString(DbMigrations.instantMixesV8));
  }

  Future<void> _migrateToV7(Database db) async {
    await _addColumn(
      db,
      table: 'QueueCache',
      column: 'Quality',
      sql: await rootBundle.loadString(DbMigrations.queueCacheV7),
    );
  }

  Future<void> _migrateToV6(Database db) async {
    await db.execute(await rootBundle.loadString(DbMigrations.queueCacheV6));
  }

  Future<void> _migrateToV5(Database db) async {
    final createV5 = [DbMigrations.playlistsV5, DbMigrations.playlistSongsV5];
    final queries = await Future.wait(createV5.map(rootBundle.loadString));
    for (final query in queries) {
      await db.execute(query);
    }
  }

  Future<void> _migrateToV4(Database db) async {
    await _addColumn(
      db,
      table: 'Downloads',
      column: 'ServerId',
      sql: await rootBundle.loadString(DbMigrations.downloadsV4),
    );
    await _addColumn(
      db,
      table: 'Albums',
      column: 'ServerId',
      sql: await rootBundle.loadString(DbMigrations.albumsV4),
    );
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
    final columns = await db.rawQuery('PRAGMA table_info(Downloads)');
    if (columns.any((column) => column['name'] == 'Data')) return;

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
    bool pending = false,
  }) async {
    final db = await database;
    return db.insert('Downloads', {
      'Id': song.id,
      'ServerId': serverId,
      'AlbumId': song.albumId,
      'FilePath': StoredFilePath.relativeTo(
        file.path,
        root: DownloadPaths.root,
      ),
      'SizeInBytes': file.lengthSync(),
      'DownloadDate': DateTime.now().millisecondsSinceEpoch,
      'Data': jsonEncode(song.toJson()),
      'Pending': pending ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> pendingSongIds() async {
    final db = await database;
    final rows = await db.query(
      'Downloads',
      columns: ['Id'],
      where: 'Pending = 1 AND ServerId = ?',
      whereArgs: [serverId],
    );
    return [for (final row in rows) row['Id']! as String];
  }

  Future<int> pruneAbandonedSongs() async {
    final abandoned = await pendingSongIds();
    if (abandoned.isEmpty) return 0;
    await pruneSongs(abandoned);
    final kept = await pendingSongIds();
    final db = await database;
    await db.update(
      'Downloads',
      {'Pending': 0},
      where: 'Pending = 1 AND ServerId = ?',
      whereArgs: [serverId],
    );
    return abandoned.length - kept.length;
  }

  Future<int> insertDownloadedAlbum(
    LibraryItem album, {
    required List<File> files,
  }) async {
    final db = await database;
    await db.update(
      'Downloads',
      {'Pending': 0},
      where: 'AlbumId = ? AND ServerId = ?',
      whereArgs: [album.id, serverId],
    );
    return db.insert('Albums', {
      'Id': album.id,
      'ServerId': serverId,
      'SizeInBytes': files.map((e) => e.lengthSync()).sum,
      'DownloadDate': DateTime.now().millisecondsSinceEpoch,
      'Data': jsonEncode(album.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertDownloadedPlaylist(
    LibraryItem playlist, {
    required List<LibraryItem> songs,
    required List<File> files,
  }) async {
    final db = await database;
    final batch = db.batch()
      ..insert('Playlists', {
        'Id': playlist.id,
        'ServerId': serverId,
        'SizeInBytes': files.map((e) => e.lengthSync()).sum,
        'DownloadDate': DateTime.now().millisecondsSinceEpoch,
        'Data': jsonEncode(playlist.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace)
      ..delete(
        'PlaylistSongs',
        where: 'PlaylistId = ? AND ServerId = ?',
        whereArgs: [playlist.id, serverId],
      );
    for (final (position, song) in songs.indexed) {
      batch
        ..insert('PlaylistSongs', {
          'PlaylistId': playlist.id,
          'SongId': song.id,
          'ServerId': serverId,
          'Position': position,
        }, conflictAlgorithm: ConflictAlgorithm.replace)
        ..update(
          'Downloads',
          {'Pending': 0},
          where: 'Id = ? AND ServerId = ?',
          whereArgs: [song.id, serverId],
        );
    }
    await batch.commit(noResult: true);
  }

  Future<List<DownloadedPlaylist>> getDownloadedPlaylists() async {
    final db = await database;
    final results = await db.query(
      'Playlists',
      where: 'ServerId = ?',
      whereArgs: [serverId],
    );
    return results.map(_downloadedPlaylistFromRow).toList();
  }

  Future<List<DownloadedSong>> getDownloadedPlaylistSongs(
    String playlistId,
  ) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT d.* FROM Downloads d '
      'JOIN PlaylistSongs ps ON ps.SongId = d.Id AND ps.ServerId = d.ServerId '
      'WHERE ps.PlaylistId = ? AND ps.ServerId = ? '
      'ORDER BY ps.Position',
      [playlistId, serverId],
    );
    return _songsFromRows(results);
  }

  Future<List<String>> getPlaylistSongIds(String playlistId) async {
    final db = await database;
    final rows = await db.query(
      'PlaylistSongs',
      columns: ['SongId'],
      where: 'PlaylistId = ? AND ServerId = ?',
      whereArgs: [playlistId, serverId],
      orderBy: 'Position',
    );
    return rows.map((row) => row['SongId']! as String).toList();
  }

  Future<void> deleteDownloadedPlaylist(String playlistId) async {
    final db = await database;
    final songIds = await getPlaylistSongIds(playlistId);

    final batch = db.batch()
      ..delete(
        'PlaylistSongs',
        where: 'PlaylistId = ? AND ServerId = ?',
        whereArgs: [playlistId, serverId],
      )
      ..delete(
        'Playlists',
        where: 'Id = ? AND ServerId = ?',
        whereArgs: [playlistId, serverId],
      );
    await batch.commit(noResult: true);

    await pruneSongs(songIds);
  }

  Future<void> pruneSongs(Iterable<String> songIds) async {
    final db = await database;
    for (final songId in songIds.toSet()) {
      final refs = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM PlaylistSongs '
          'WHERE SongId = ? AND ServerId = ?',
          [songId, serverId],
        ),
      )!;
      if (refs > 0) continue;

      final songRows = await db.query(
        'Downloads',
        columns: ['AlbumId'],
        where: 'Id = ? AND ServerId = ?',
        whereArgs: [songId, serverId],
      );
      if (songRows.isEmpty) continue;
      final albumId = songRows.first['AlbumId'] as String?;
      if (albumId != null && await isAlbumDownloaded(albumId)) continue;

      await deleteDownloadedSong(songId);
    }
  }

  Future<bool> isPlaylistDownloaded(String playlistId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM Playlists WHERE Id = ? AND ServerId = ?',
        [playlistId, serverId],
      ),
    );
    return count! > 0;
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
    return _songsFromRows(results);
  }

  Future<List<DownloadedSong>> getStandaloneSongs() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT d.* FROM Downloads d '
      'WHERE d.ServerId = ? AND d.Pending = 0 '
      'AND NOT EXISTS (SELECT 1 FROM PlaylistSongs ps '
      'WHERE ps.SongId = d.Id AND ps.ServerId = d.ServerId) '
      'AND NOT EXISTS (SELECT 1 FROM Albums a '
      'WHERE a.Id = d.AlbumId AND a.ServerId = d.ServerId) '
      'ORDER BY d.DownloadDate DESC',
      [serverId],
    );
    return _songsFromRows(results);
  }

  Future<List<DownloadedSong>> _songsFromRows(
    List<Map<String, Object?>> rows,
  ) async {
    final root = await _musicRoot();
    return [for (final row in rows) _downloadedSongFromRow(row, root)];
  }

  Future<String?> _musicRoot() async {
    final root = DownloadPaths.root;
    if (root != null) return root;
    try {
      return await DownloadPaths.init();
    } on Object {
      return null;
    }
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

  Future<Set<String>> albumIds() => _ids('Albums');

  Future<Set<String>> playlistIds() => _ids('Playlists');

  Future<Set<String>> _ids(String table) async {
    final db = await database;
    final rows = await db.query(
      table,
      columns: ['Id'],
      where: 'ServerId = ?',
      whereArgs: [serverId],
    );
    return {for (final row in rows) row['Id']! as String};
  }

  Future<Set<String>> downloadedAlbumIds() async {
    final db = await database;
    final albums = await db.query('Albums', columns: ['Id']);
    final songs = await db.query(
      'Downloads',
      columns: ['AlbumId'],
      distinct: true,
      where: 'AlbumId IS NOT NULL',
    );
    return {
      for (final row in albums) row['Id']! as String,
      for (final row in songs) row['AlbumId']! as String,
    };
  }

  Future<Set<String>> downloadedIds(Iterable<String> ids) async {
    final wanted = ids.toSet().toList();
    if (wanted.isEmpty) return const {};
    final db = await database;
    final found = <String>{};
    for (var start = 0; start < wanted.length; start += 500) {
      final chunk = wanted.sublist(start, min(start + 500, wanted.length));
      final placeholders = List.filled(chunk.length, '?').join(', ');
      final results = await db.query(
        'Downloads',
        columns: ['Id'],
        where: 'ServerId = ? AND Id IN ($placeholders)',
        whereArgs: [serverId, ...chunk],
      );
      found.addAll(results.map((row) => row['Id']! as String));
    }
    return found;
  }

  Future<String?> getDownloadedSongPath(String id) async {
    final db = await database;
    final results = await db.query(
      'Downloads',
      columns: ['FilePath'],
      where: 'Id = ? AND ServerId = ?',
      whereArgs: [id, serverId],
    );

    final stored = results.firstOrNull?['FilePath'] as String?;
    if (stored == null) return null;
    return StoredFilePath.resolve(stored, root: await _musicRoot(), depth: 2);
  }

  Future<Map<String, String>> downloadedPathsFor(Iterable<String> ids) async {
    final wanted = ids.toSet().toList();
    if (wanted.isEmpty) return const {};
    final db = await database;
    final root = await _musicRoot();
    final paths = <String, String>{};
    const chunkSize = 500;
    for (var start = 0; start < wanted.length; start += chunkSize) {
      final chunk = wanted.sublist(start, min(start + chunkSize, wanted.length));
      final results = await db.query(
        'Downloads',
        columns: ['Id', 'FilePath'],
        where: 'ServerId = ? AND Id IN (${List.filled(chunk.length, '?').join(', ')})',
        whereArgs: [serverId, ...chunk],
      );
      for (final row in results) {
        final stored = row['FilePath'] as String?;
        if (stored == null) continue;
        final path = StoredFilePath.resolve(stored, root: root, depth: 2);
        if (path != null) paths[row['Id']! as String] = path;
      }
    }
    return paths;
  }
}

DownloadedSong _downloadedSongFromRow(Map<String, Object?> row, String? root) {
  final stored = row['FilePath']! as String;
  final resolved = StoredFilePath.resolve(stored, root: root, depth: 2);
  return DownloadedSong(
    item: LibraryItem.fromJson(
      jsonDecode(row['Data']! as String) as Map<String, dynamic>,
    ),
    filePath: resolved ?? (root == null ? stored : join(root, '.missing')),
    sizeInBytes: row['SizeInBytes']! as int,
    downloadDate: DateTime.fromMillisecondsSinceEpoch(
      row['DownloadDate']! as int,
    ),
  );
}

DownloadedPlaylist _downloadedPlaylistFromRow(Map<String, Object?> row) =>
    DownloadedPlaylist(
      item: LibraryItem.fromJson(
        jsonDecode(row['Data']! as String) as Map<String, dynamic>,
      ),
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
