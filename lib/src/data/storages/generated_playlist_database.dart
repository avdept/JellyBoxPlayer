import 'dart:convert';

import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:sqflite/sqflite.dart';

const generatedPlaylistRetentionDays = 7;

typedef StoredGeneratedPlaylist = ({
  GeneratedPlaylist playlist,
  String dayKey,
});

String generatedPlaylistDayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class GeneratedPlaylistDatabase {
  GeneratedPlaylistDatabase(this._owner);

  static const _playlists = 'GeneratedPlaylists';
  static const _items = 'GeneratedPlaylistItems';
  static const _allLibraries = '';

  final DownloadDatabase _owner;

  Future<Database> get _database => _owner.database;

  String _scope(String? libraryId) => libraryId ?? _allLibraries;

  Future<List<GeneratedPlaylist>> getPlaylists({
    required String userId,
    required String dayKey,
    String? libraryId,
  }) async {
    final db = await _database;
    final rows = await db.query(
      _playlists,
      where: 'UserId = ? AND LibraryId = ? AND DayKey = ?',
      whereArgs: [userId, _scope(libraryId), dayKey],
      orderBy: 'Position ASC',
    );
    return rows.map(_playlistFromRow).toList();
  }

  Future<void> savePlaylists(
    List<GeneratedPlaylist> playlists, {
    required String userId,
    required String dayKey,
    String? libraryId,
  }) async {
    final db = await _database;
    final scope = _scope(libraryId);
    final generatedAt = DateTime.now().millisecondsSinceEpoch;

    final batch = db.batch()
      ..delete(
        _playlists,
        where: 'UserId = ? AND LibraryId = ? AND DayKey = ?',
        whereArgs: [userId, scope, dayKey],
      )
      ..delete(
        _items,
        where: 'UserId = ? AND LibraryId = ? AND DayKey = ?',
        whereArgs: [userId, scope, dayKey],
      );

    for (var index = 0; index < playlists.length; index++) {
      final playlist = playlists[index];
      batch.insert(_playlists, {
        'Id': playlist.item.id,
        'UserId': userId,
        'LibraryId': scope,
        'DayKey': dayKey,
        'Position': index,
        'GeneratedAt': generatedAt,
        'RemoteId': playlist.remoteId,
        'SyncedAt': playlist.syncedAt?.millisecondsSinceEpoch,
        'Data': jsonEncode(playlist.item.toJson()),
        'CoverSongs': jsonEncode([
          for (final song in playlist.coverSongs) song.toJson(),
        ]),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    await _prune(db, dayKey);
  }

  Future<List<LibraryItem>> getSongs({
    required String playlistId,
    required String userId,
    required String dayKey,
    String? libraryId,
  }) async {
    final db = await _database;
    final rows = await db.query(
      _items,
      where: 'PlaylistId = ? AND UserId = ? AND LibraryId = ? AND DayKey = ?',
      whereArgs: [playlistId, userId, _scope(libraryId), dayKey],
      orderBy: 'Position ASC',
    );
    return [for (final row in rows) _itemFromRow(row)];
  }

  Future<void> saveSongs(
    List<LibraryItem> songs, {
    required String playlistId,
    required String userId,
    required String dayKey,
    String? libraryId,
  }) async {
    final db = await _database;
    final scope = _scope(libraryId);

    final batch = db.batch()
      ..delete(
        _items,
        where: 'PlaylistId = ? AND UserId = ? AND LibraryId = ? AND DayKey = ?',
        whereArgs: [playlistId, userId, scope, dayKey],
      );

    for (var index = 0; index < songs.length; index++) {
      batch.insert(_items, {
        'PlaylistId': playlistId,
        'UserId': userId,
        'LibraryId': scope,
        'DayKey': dayKey,
        'Position': index,
        'SongId': songs[index].id,
        'Data': jsonEncode(songs[index].toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<int> updateSong(
    LibraryItem song, {
    required String userId,
    required String dayKey,
    String? libraryId,
  }) async {
    final db = await _database;
    return db.update(
      _items,
      {'Data': jsonEncode(song.toJson())},
      where: 'SongId = ? AND UserId = ? AND LibraryId = ? AND DayKey = ?',
      whereArgs: [song.id, userId, _scope(libraryId), dayKey],
    );
  }

  Future<List<StoredGeneratedPlaylist>> getUnsynced({
    required String userId,
    String? libraryId,
  }) async {
    final db = await _database;
    final rows = await db.query(
      _playlists,
      where: 'UserId = ? AND LibraryId = ? AND RemoteId IS NULL',
      whereArgs: [userId, _scope(libraryId)],
      orderBy: 'DayKey ASC, Position ASC',
    );
    return [
      for (final row in rows)
        (playlist: _playlistFromRow(row), dayKey: row['DayKey']! as String),
    ];
  }

  Future<int> markSynced({
    required String playlistId,
    required String userId,
    required String dayKey,
    required String remoteId,
    String? libraryId,
  }) async {
    final db = await _database;
    return db.update(
      _playlists,
      {
        'RemoteId': remoteId,
        'SyncedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'Id = ? AND UserId = ? AND LibraryId = ? AND DayKey = ?',
      whereArgs: [playlistId, userId, _scope(libraryId), dayKey],
    );
  }

  Future<void> _prune(Database db, String dayKey) async {
    final cutoff = generatedPlaylistDayKey(
      DateTime.parse(
        dayKey,
      ).subtract(const Duration(days: generatedPlaylistRetentionDays)),
    );
    final batch = db.batch()
      ..delete(_playlists, where: 'DayKey < ?', whereArgs: [cutoff])
      ..delete(_items, where: 'DayKey < ?', whereArgs: [cutoff]);
    await batch.commit(noResult: true);
  }
}

GeneratedPlaylist _playlistFromRow(Map<String, Object?> row) {
  final syncedAt = row['SyncedAt'] as int?;
  final libraryId = row['LibraryId']! as String;
  return GeneratedPlaylist(
    item: LibraryItem.fromJson(
      jsonDecode(row['Data']! as String) as Map<String, dynamic>,
    ),
    libraryId: libraryId.isEmpty ? null : libraryId,
    coverSongs: [
      for (final song in jsonDecode(row['CoverSongs']! as String) as List)
        LibraryItem.fromJson(song as Map<String, dynamic>),
    ],
    remoteId: row['RemoteId'] as String?,
    syncedAt: syncedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(syncedAt),
  );
}

LibraryItem _itemFromRow(Map<String, Object?> row) => LibraryItem.fromJson(
  jsonDecode(row['Data']! as String) as Map<String, dynamic>,
);
