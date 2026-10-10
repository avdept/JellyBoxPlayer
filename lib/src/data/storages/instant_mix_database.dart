import 'dart:convert';

import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:sqflite/sqflite.dart';

class InstantMixDatabase {
  InstantMixDatabase(this._owner, {this.userId});

  static const _table = 'InstantMixes';
  static const _allLibraries = '';

  final DownloadDatabase _owner;
  final String? userId;

  Future<Database> get _database => _owner.database;

  String get _serverId => _owner.serverId;

  Future<List<InstantMix>> getMixes() async {
    if (userId == null) return const [];
    final db = await _database;
    final rows = await db.query(
      _table,
      where: 'ServerId = ? AND UserId = ?',
      whereArgs: [_serverId, userId],
      orderBy: 'LastUsedAt DESC',
    );
    return rows.map(_mixFromRow).toList();
  }

  Future<void> saveMix(InstantMix mix, {required int keep}) async {
    if (userId == null) return;
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert(_table, {
        'Id': mix.item.id,
        'ServerId': _serverId,
        'UserId': userId,
        'LibraryId': mix.libraryId ?? _allLibraries,
        'Seed': jsonEncode(mix.seed.toJson()),
        'Songs': _encodeSongs(mix.songs),
        'LastUsedAt': DateTime.now().microsecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete(
        _table,
        where:
            'ServerId = ? AND UserId = ? AND Id NOT IN '
            '(SELECT Id FROM $_table WHERE ServerId = ? AND UserId = ? '
            'ORDER BY LastUsedAt DESC LIMIT ?)',
        whereArgs: [_serverId, userId, _serverId, userId, keep],
      );
    });
  }

  Future<void> updateSongs(InstantMix mix) async {
    if (userId == null) return;
    final db = await _database;
    await db.update(
      _table,
      {'Songs': _encodeSongs(mix.songs)},
      where: 'Id = ? AND ServerId = ? AND UserId = ?',
      whereArgs: [mix.item.id, _serverId, userId],
    );
  }

  static String _encodeSongs(List<LibraryItem> songs) =>
      jsonEncode([for (final song in songs) song.toJson()]);

  static InstantMix _mixFromRow(Map<String, Object?> row) {
    final libraryId = row['LibraryId']! as String;
    final seed = LibraryItem.fromJson(
      jsonDecode(row['Seed']! as String) as Map<String, dynamic>,
    );
    return InstantMix(
      item: instantMixItem(
        seed,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ).copyWith(id: row['Id']! as String),
      seed: seed,
      songs: [
        for (final song in jsonDecode(row['Songs']! as String) as List)
          LibraryItem.fromJson(song as Map<String, dynamic>),
      ],
      libraryId: libraryId == _allLibraries ? null : libraryId,
    );
  }
}
