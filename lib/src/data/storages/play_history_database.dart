import 'dart:convert';

import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:sqflite/sqflite.dart';

typedef SongPlay = ({LibraryItem song, DateTime playedAt});

typedef PlayCountRow = ({String songId, int playCount, DateTime lastPlayed});

class PlayHistoryDatabase {
  PlayHistoryDatabase(this._owner, {this.userId});

  static const _plays = 'SongPlays';
  static const _songs = 'PlayedSongs';
  static const localSource = 'local';

  final DownloadDatabase _owner;
  final String? userId;

  Future<Database> get _database => _owner.database;

  String get _serverId => _owner.serverId;

  Future<void> addPlays(
    Iterable<SongPlay> plays, {
    String source = localSource,
  }) async {
    final userId = this.userId;
    if (userId == null || plays.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    final updatedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final play in plays) {
      batch
        ..insert(_plays, {
          'ServerId': _serverId,
          'UserId': userId,
          'SongId': play.song.id,
          'PlayedAt': play.playedAt.toUtc().millisecondsSinceEpoch,
          'Source': source,
        }, conflictAlgorithm: ConflictAlgorithm.ignore)
        ..insert(_songs, {
          'ServerId': _serverId,
          'SongId': play.song.id,
          'Item': jsonEncode(
            play.song.copyWith(userData: const PlaybackUserData()).toJson(),
          ),
          'UpdatedAt': updatedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<PlayCountRow>> topPlayed({
    required Duration window,
    required int limit,
    DateTime Function() now = DateTime.now,
  }) async {
    final userId = this.userId;
    if (userId == null) return const [];
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT SongId, COUNT(*) AS PlayCount, MAX(PlayedAt) AS LastPlayed '
      'FROM $_plays WHERE ServerId = ? AND UserId = ? AND PlayedAt >= ? '
      'GROUP BY SongId ORDER BY PlayCount DESC, LastPlayed DESC LIMIT ?',
      [
        _serverId,
        userId,
        now().toUtc().subtract(window).millisecondsSinceEpoch,
        limit,
      ],
    );
    return [
      for (final row in rows)
        (
          songId: row['SongId']! as String,
          playCount: row['PlayCount']! as int,
          lastPlayed: DateTime.fromMillisecondsSinceEpoch(
            row['LastPlayed']! as int,
            isUtc: true,
          ),
        ),
    ];
  }

  Future<Map<String, LibraryItem>> playedSongsByIds(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final db = await _database;
    final rows = await db.query(
      _songs,
      columns: ['SongId', 'Item'],
      where:
          'ServerId = ? AND SongId IN '
          '(${List.filled(ids.length, '?').join(',')})',
      whereArgs: [_serverId, ...ids],
    );
    return {
      for (final row in rows)
        row['SongId']! as String: LibraryItem.fromJson(
          jsonDecode(row['Item']! as String) as Map<String, dynamic>,
        ),
    };
  }

  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_plays, where: 'ServerId = ?', whereArgs: [_serverId]);
    await db.delete(_songs, where: 'ServerId = ?', whereArgs: [_serverId]);
  }
}
