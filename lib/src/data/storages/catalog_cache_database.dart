import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:optional_features/catalog.dart';
import 'package:sqflite/sqflite.dart';

typedef CatalogArtistLink = ({String? catalogId, DateTime checkedAt});

class CatalogCacheDatabase implements CatalogCacheStore {
  CatalogCacheDatabase(this._owner, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _cache = 'CatalogCache';
  static const _links = 'CatalogArtistLinks';
  static const defaultBudgetBytes = 10 * 1024 * 1024;

  final DownloadDatabase _owner;
  final DateTime Function() _now;

  Future<Database> get _database => _owner.database;

  @override
  Future<CatalogCacheEntry?> read(String source, String key) async {
    final db = await _database;
    final rows = await db.query(
      _cache,
      columns: ['Json', 'FetchedAt', 'ExpiresAt'],
      where: 'Source = ? AND Key = ?',
      whereArgs: [source, key],
      limit: 1,
    );
    final row = rows.firstOrNull;
    if (row == null) return null;
    return CatalogCacheEntry(
      json: row['Json']! as String,
      fetchedAt: _time(row['FetchedAt']),
      expires: _time(row['ExpiresAt']),
    );
  }

  @override
  Future<void> write(
    String source,
    String key,
    String json, {
    required DateTime expires,
  }) async {
    final db = await _database;
    await db.insert(_cache, {
      'Source': source,
      'Key': key,
      'Json': json,
      'FetchedAt': _now().millisecondsSinceEpoch,
      'ExpiresAt': expires.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> prune({int budgetBytes = defaultBudgetBytes}) async {
    final db = await _database;
    await db.delete(
      _cache,
      where: 'ExpiresAt < ?',
      whereArgs: [_now().millisecondsSinceEpoch],
    );
    final rows = await db.query(
      _cache,
      columns: ['Source', 'Key', 'LENGTH(Json) AS Size'],
      orderBy: 'FetchedAt DESC',
    );
    var used = 0;
    final batch = db.batch();
    var dirty = false;
    for (final row in rows) {
      used += (row['Size']! as num).toInt();
      if (used <= budgetBytes) continue;
      dirty = true;
      batch.delete(
        _cache,
        where: 'Source = ? AND Key = ?',
        whereArgs: [row['Source'], row['Key']],
      );
    }
    if (dirty) await batch.commit(noResult: true);
  }

  Future<void> clear({String? source}) async {
    final db = await _database;
    await db.delete(
      _cache,
      where: source == null ? null : 'Source = ?',
      whereArgs: source == null ? null : [source],
    );
    await db.delete(
      _links,
      where: source == null ? null : 'Source = ?',
      whereArgs: source == null ? null : [source],
    );
  }

  Future<CatalogArtistLink?> artistLink(String artistId, String source) async {
    final db = await _database;
    final rows = await db.query(
      _links,
      columns: ['CatalogId', 'CheckedAt'],
      where: 'ServerId = ? AND ArtistId = ? AND Source = ?',
      whereArgs: [_owner.serverId, artistId, source],
      limit: 1,
    );
    final row = rows.firstOrNull;
    if (row == null) return null;
    return (
      catalogId: row['CatalogId'] as String?,
      checkedAt: _time(row['CheckedAt']),
    );
  }

  Future<void> saveArtistLink(
    String artistId,
    String source, {
    required String? catalogId,
  }) async {
    final db = await _database;
    await db.insert(_links, {
      'ServerId': _owner.serverId,
      'ArtistId': artistId,
      'Source': source,
      'CatalogId': catalogId,
      'CheckedAt': _now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static DateTime _time(Object? value) =>
      DateTime.fromMillisecondsSinceEpoch((value! as num).toInt(), isUtc: true);
}
