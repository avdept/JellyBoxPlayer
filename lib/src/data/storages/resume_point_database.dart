import 'dart:convert';

import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:sqflite/sqflite.dart';

class ResumePointDatabase {
  ResumePointDatabase(this._owner, {this.userId});

  static const _table = 'ResumePoints';
  static const _unknownLibrary = '';

  final DownloadDatabase _owner;
  final String? userId;

  Future<Database> get _database => _owner.database;

  String get _serverId => _owner.serverId;

  Future<void> save(ResumePoint point, {String? libraryId}) async {
    if (userId == null) return;
    final db = await _database;
    await db.insert(_table, {
      'ServerId': _serverId,
      'UserId': userId,
      'SourceId': point.item.id,
      'LibraryId': libraryId ?? _unknownLibrary,
      'Item': jsonEncode(
        point.item.copyWith(userData: const PlaybackUserData()).toJson(),
      ),
      'SongId': point.songId,
      'SongName': point.songName,
      'SongIndex': point.songIndex,
      'SongCount': point.songCount,
      'PositionMs': point.position.inMilliseconds,
      'UpdatedAt': point.updatedAt.toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ResumePoint?> get(
    String sourceId, {
    String? libraryId,
    Duration? maxAge,
    DateTime Function() now = DateTime.now,
  }) async {
    if (userId == null) return null;
    final db = await _database;
    final rows = await db.query(
      _table,
      where:
          'ServerId = ? AND UserId = ? AND SourceId = ? AND UpdatedAt >= ? '
          'AND ${_resumableClause()} AND ${_libraryClause(libraryId)}',
      whereArgs: [
        _serverId,
        userId,
        sourceId,
        _cutoff(maxAge, now),
        ?libraryId,
      ],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  Future<List<ResumePoint>> recent({
    String? libraryId,
    Duration? maxAge,
    int limit = 20,
    DateTime Function() now = DateTime.now,
  }) async {
    if (userId == null) return const [];
    final db = await _database;
    final rows = await db.query(
      _table,
      where:
          'ServerId = ? AND UserId = ? AND UpdatedAt >= ? '
          'AND ${_resumableClause()} AND ${_libraryClause(libraryId)}',
      whereArgs: [_serverId, userId, _cutoff(maxAge, now), ?libraryId],
      orderBy: 'UpdatedAt DESC',
      limit: limit,
    );
    return [
      for (final point in rows.map(_fromRow))
        if (point.item.name.isNotEmpty) point,
    ];
  }

  Future<List<ResumePoint>> stubs() async => [
    for (final point in await all())
      if (point.item.name.isEmpty ||
          (point.songName.isEmpty && point.songId.isNotEmpty))
        point,
  ];

  Future<void> fill(
    String sourceId, {
    LibraryItem? item,
    String? songName,
  }) async {
    if (userId == null || (item == null && songName == null)) return;
    final db = await _database;
    await db.update(
      _table,
      {
        if (item != null)
          'Item': jsonEncode(
            item.copyWith(userData: const PlaybackUserData()).toJson(),
          ),
        'SongName': ?songName,
      },
      where: 'ServerId = ? AND UserId = ? AND SourceId = ?',
      whereArgs: [_serverId, userId, sourceId],
    );
  }

  Future<List<ResumePoint>> all() async {
    if (userId == null) return const [];
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'ServerId = ? AND UserId = ?',
      whereArgs: [_serverId, userId],
      orderBy: 'UpdatedAt DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> delete(String sourceId) async {
    if (userId == null) return;
    final db = await _database;
    await db.delete(
      _table,
      where: 'ServerId = ? AND UserId = ? AND SourceId = ?',
      whereArgs: [_serverId, userId, sourceId],
    );
  }

  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_table, where: 'ServerId = ?', whereArgs: [_serverId]);
  }

  static String _libraryClause(String? libraryId) => libraryId == null
      ? '1'
      : "(LibraryId = ? OR LibraryId = '$_unknownLibrary')";

  static String _resumableClause() =>
      '(SongIndex > 0 OR PositionMs >= ${resumePointMinPosition.inMilliseconds})';

  static int _cutoff(Duration? maxAge, DateTime Function() now) =>
      maxAge == null
      ? 0
      : now().toUtc().subtract(maxAge).millisecondsSinceEpoch;

  static ResumePoint _fromRow(Map<String, Object?> row) => (
    item: LibraryItem.fromJson(
      jsonDecode(row['Item']! as String) as Map<String, dynamic>,
    ),
    songId: row['SongId']! as String,
    songName: row['SongName']! as String,
    songIndex: row['SongIndex']! as int,
    songCount: row['SongCount']! as int,
    position: Duration(milliseconds: row['PositionMs']! as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      row['UpdatedAt']! as int,
      isUtc: true,
    ),
  );
}
