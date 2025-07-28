import 'dart:io' show File;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DownloadDatabase {
  DownloadDatabase([
    @visibleForTesting Database? db,
  ]) : _db = db;

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _initDB('downloads.db');
    return _db!;
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
      '''),
      db.execute('''
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
      '''),
    ]);
  }

  Future<int> insertDownloadedSong(
    ItemDTO song, {
    required File file,
  }) async {
    final db = await _database;
    final songData = DownloadedSongDTO.fromSong(
      song,
      filePath: file.path,
      sizeInBytes: file.lengthSync(),
    );
    return db.insert('Downloads', songData.toJson());
  }

  Future<int> insertDownloadedAlbum(
    ItemDTO album, {
    required List<File> files,
  }) async {
    final db = await _database;
    final albumData = DownloadedAlbumDTO.fromAlbum(
      album,
      sizeInBytes: files.map((e) => e.lengthSync()).sum,
    );
    return db.insert('Albums', albumData.toJson());
  }

  Future<List<DownloadedSongDTO>> getDownloadedSongs([
    String? albumId,
  ]) async {
    final db = await _database;
    final results = (albumId == null)
        ? await db.query('Downloads')
        : await db.query(
            'Downloads',
            where: 'AlbumId = ?',
            whereArgs: [albumId],
          );
    return results.map(DownloadedSongDTO.fromJson).toList();
  }

  Future<List<DownloadedAlbumDTO>> getDownloadedAlbums() async {
    final db = await _database;
    final results = await db.query('Albums');
    return results.map(DownloadedAlbumDTO.fromJson).toList();
  }

  Future<int> deleteDownloadedSong(String id) async {
    final db = await _database;
    final filePath = await getDownloadedSongPath(id);

    if (filePath != null) {
      // Delete file
      final file = File(filePath);
      if (file.existsSync()) await file.delete();
    }

    return db.delete(
      'Downloads',
      where: 'Id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDownloadedAlbum(String albumId) async {
    final db = await _database;
    final songs = await getDownloadedSongs(albumId);

    // Delete each song file
    for (final song in songs) {
      final file = File(song.filePath);
      if (file.existsSync()) await file.delete();
    }

    final batch = db.batch()
      // Delete the album entry
      ..delete(
        'Albums',
        where: 'Id = ?',
        whereArgs: [albumId],
      )
      // Delete all songs from this album
      ..delete(
        'Downloads',
        where: 'AlbumId = ?',
        whereArgs: [albumId],
      );

    await batch.commit();
  }

  Future<bool> isSongDownloaded(String id) async {
    final db = await _database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM Downloads WHERE Id = ?', [id]),
    );
    return count! > 0;
  }

  Future<bool> isAlbumDownloaded(String albumId) async {
    final db = await _database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM Albums WHERE Id = ?', [albumId]),
    );
    return count! > 0;
  }

  Future<String?> getDownloadedSongPath(String id) async {
    final db = await _database;
    final results = await db.query(
      'Downloads',
      columns: ['FilePath'],
      where: 'Id = ?',
      whereArgs: [id],
    );

    return results.firstOrNull?['FilePath'] as String?;
  }

  Future<void> close() async {
    final db = await _database;
    return db.close();
  }
}
