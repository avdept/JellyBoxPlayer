import 'dart:convert';
import 'dart:io' show File;
import 'dart:math' show min;

import 'package:jplayer/src/core/downloads/cache_downloader.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

typedef CacheEntry = ({String id, String filePath, int sizeInBytes});

typedef CacheDetail = ({
  LibraryItem item,
  String filePath,
  int sizeInBytes,
  DateTime cachedDate,
  DateTime lastUsedDate,
  bool onDisk,
});

class QueueCacheDatabase {
  QueueCacheDatabase(this._owner, {Future<String?> Function()? directory})
    : _directory = directory ?? _defaultDirectory;

  static const _table = 'QueueCache';
  static const _chunkSize = 500;

  static Future<String?> _defaultDirectory() async {
    try {
      return await BackgroundCacheDownloader().directoryPath();
    } on Object {
      return null;
    }
  }

  final DownloadDatabase _owner;
  final Future<String?> Function() _directory;

  String? _root;

  Future<Database> get _database => _owner.database;

  String get _serverId => _owner.serverId;

  Future<String?> _cacheRoot() async => _root ??= await _directory();

  String? _resolve(String stored, String? root) =>
      StoredFilePath.resolve(stored, root: root, depth: 1);

  String _resolveOrInert(String stored, String? root) =>
      _resolve(stored, root) ??
      (root == null ? stored : p.join(root, '.missing'));

  Future<void> insert(
    LibraryItem song, {
    required File file,
    AudioSourceInfo? quality,
  }) async {
    final db = await _database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(_table, {
      'Id': song.id,
      'ServerId': _serverId,
      'FilePath': p.basename(file.path),
      'SizeInBytes': file.lengthSync(),
      'CachedDate': now,
      'LastUsedDate': now,
      'Data': jsonEncode(song.toJson()),
      'Quality': quality == null ? null : jsonEncode(quality.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AudioSourceInfo?> qualityOf(String id) async {
    final db = await _database;
    final results = await db.query(
      _table,
      columns: ['Quality'],
      where: 'Id = ? AND ServerId = ?',
      whereArgs: [id, _serverId],
    );
    final stored = results.firstOrNull?['Quality'] as String?;
    if (stored == null) return null;
    return AudioSourceInfo.fromJson(jsonDecode(stored) as Map<String, dynamic>);
  }

  Future<String?> pathOf(String id) async {
    final db = await _database;
    final results = await db.query(
      _table,
      columns: ['FilePath'],
      where: 'Id = ? AND ServerId = ?',
      whereArgs: [id, _serverId],
    );
    final stored = results.firstOrNull?['FilePath'] as String?;
    if (stored == null) return null;
    return _resolve(stored, await _cacheRoot());
  }

  Future<Map<String, String>> pathsFor(Iterable<String> ids) async {
    final wanted = ids.toSet().toList();
    if (wanted.isEmpty) return const {};
    final db = await _database;
    final root = await _cacheRoot();
    final paths = <String, String>{};
    for (var start = 0; start < wanted.length; start += _chunkSize) {
      final chunk = wanted.sublist(
        start,
        min(start + _chunkSize, wanted.length),
      );
      final results = await db.query(
        _table,
        columns: ['Id', 'FilePath'],
        where: 'ServerId = ? AND Id IN (${_placeholders(chunk.length)})',
        whereArgs: [_serverId, ...chunk],
      );
      for (final row in results) {
        final path = _resolve(row['FilePath']! as String, root);
        if (path == null) continue;
        if (File(path).existsSync()) paths[row['Id']! as String] = path;
      }
    }
    return paths;
  }

  Future<Set<String>> cachedIds() async {
    final db = await _database;
    final results = await db.query(
      _table,
      columns: ['Id'],
      where: 'ServerId = ?',
      whereArgs: [_serverId],
    );
    return {for (final row in results) row['Id']! as String};
  }

  Future<void> touch(String id) async {
    final db = await _database;
    await db.update(
      _table,
      {'LastUsedDate': DateTime.now().millisecondsSinceEpoch},
      where: 'Id = ? AND ServerId = ?',
      whereArgs: [id, _serverId],
    );
  }

  Future<int> totalBytes() async {
    final db = await _database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT SUM(SizeInBytes) FROM $_table WHERE ServerId = ?',
            [_serverId],
          ),
        ) ??
        0;
  }

  Future<List<CacheEntry>> entries() => _entries(orderBy: 'LastUsedDate DESC');

  Future<List<CacheEntry>> leastRecentlyUsed({
    Set<String> excludedIds = const {},
  }) async {
    final all = await _entries(orderBy: 'LastUsedDate ASC');
    return [
      for (final entry in all)
        if (!excludedIds.contains(entry.id)) entry,
    ];
  }

  Future<List<CacheEntry>> _entries({required String orderBy}) async {
    final db = await _database;
    final root = await _cacheRoot();
    final results = await db.query(
      _table,
      columns: ['Id', 'FilePath', 'SizeInBytes'],
      where: 'ServerId = ?',
      whereArgs: [_serverId],
      orderBy: orderBy,
    );
    return [
      for (final row in results)
        (
          id: row['Id']! as String,
          filePath: _resolveOrInert(row['FilePath']! as String, root),
          sizeInBytes: row['SizeInBytes']! as int,
        ),
    ];
  }

  Future<List<CacheDetail>> detailedEntries() async {
    final db = await _database;
    final root = await _cacheRoot();
    final results = await db.query(
      _table,
      where: 'ServerId = ?',
      whereArgs: [_serverId],
      orderBy: 'LastUsedDate DESC',
    );
    return [
      for (final row in results)
        (
          item: LibraryItem.fromJson(
            jsonDecode(row['Data']! as String) as Map<String, dynamic>,
          ),
          filePath: _resolveOrInert(row['FilePath']! as String, root),
          sizeInBytes: row['SizeInBytes']! as int,
          cachedDate: DateTime.fromMillisecondsSinceEpoch(
            row['CachedDate']! as int,
          ),
          lastUsedDate: DateTime.fromMillisecondsSinceEpoch(
            row['LastUsedDate']! as int,
          ),
          onDisk: switch (_resolve(row['FilePath']! as String, root)) {
            null => false,
            final path => File(path).existsSync(),
          },
        ),
    ];
  }

  Future<Set<String>> allFilePaths() async {
    final db = await _database;
    final root = await _cacheRoot();
    final results = await db.query(_table, columns: ['FilePath']);
    return {
      for (final row in results) ?_resolve(row['FilePath']! as String, root),
    };
  }

  Future<int> pruneMissing() async {
    if (await _cacheRoot() == null) return 0;
    var removed = 0;
    for (final entry in await entries()) {
      if (!File(entry.filePath).existsSync()) {
        await delete(entry.id);
        removed++;
      }
    }
    return removed;
  }

  Future<void> deleteForeignServers() async {
    if (_serverId.isEmpty) return;
    final db = await _database;
    final root = await _cacheRoot();
    final results = await db.query(
      _table,
      columns: ['FilePath'],
      where: 'ServerId != ?',
      whereArgs: [_serverId],
    );
    for (final row in results) {
      final path = _resolve(row['FilePath']! as String, root);
      if (path == null) continue;
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    await db.delete(_table, where: 'ServerId != ?', whereArgs: [_serverId]);
  }

  Future<void> delete(String id) async {
    final db = await _database;
    final path = await pathOf(id);
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
    await db.delete(
      _table,
      where: 'Id = ? AND ServerId = ?',
      whereArgs: [id, _serverId],
    );
  }

  Future<void> deleteAll() async {
    final db = await _database;
    for (final entry in await entries()) {
      final file = File(entry.filePath);
      if (file.existsSync()) await file.delete();
    }
    await db.delete(_table, where: 'ServerId = ?', whereArgs: [_serverId]);
  }

  static String _placeholders(int count) => List.filled(count, '?').join(', ');
}
