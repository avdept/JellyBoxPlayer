import 'dart:convert';

import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:sqflite/sqflite.dart';

class ResumePointDatabase {
  ResumePointDatabase(this._owner, {this.userId});

  static const _table = 'ResumePoints';

  final DownloadDatabase _owner;
  final String? userId;

  Future<Database> get _database => _owner.database;

  String get _serverId => _owner.serverId;

  Future<void> save(ResumePoint point) async {
    if (userId == null) return;
    final db = await _database;
    await db.insert(_table, {
      'ServerId': _serverId,
      'UserId': userId,
      'SourceId': point.item.id,
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
    Duration? maxAge,
    DateTime Function() now = DateTime.now,
  }) async {
    if (userId == null) return null;
    final db = await _database;
    final rows = await db.query(
      _table,
      where:
          'ServerId = ? AND UserId = ? AND SourceId = ? AND UpdatedAt >= ? '
          'AND ${_resumableClause()}',
      whereArgs: [_serverId, userId, sourceId, _cutoff(maxAge, now)],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  Future<List<ResumePoint>> recent({
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
          'AND ${_resumableClause()}',
      whereArgs: [_serverId, userId, _cutoff(maxAge, now)],
      orderBy: 'UpdatedAt DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
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

  static String _resumableClause() =>
      '(SongIndex > 0 OR PositionMs >= ${resumePointMinPosition.inMilliseconds})';

  static int _cutoff(Duration? maxAge, DateTime Function() now) => maxAge == null
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
