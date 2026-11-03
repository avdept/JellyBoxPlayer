import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:sqflite/sqflite.dart';

class PinsDatabase {
  PinsDatabase(this._owner, {this.userId});

  static const _table = 'Pins';

  final DownloadDatabase _owner;
  final String? userId;

  Future<Database> get _database => _owner.database;

  String get _serverId => _owner.serverId;

  Future<List<PinnedItem>> getPins({
    Duration? maxAge,
    DateTime Function() now = DateTime.now,
  }) async {
    if (userId == null) return const [];
    final db = await _database;
    final cutoff = maxAge == null
        ? 0
        : now().toUtc().subtract(maxAge).millisecondsSinceEpoch;
    final rows = await db.query(
      _table,
      where: 'ServerId = ? AND UserId = ? AND PinnedAt >= ?',
      whereArgs: [_serverId, userId, cutoff],
      orderBy: 'PinnedAt DESC',
    );
    return rows.map(_pinFromRow).toList();
  }

  Future<void> pin(PinnedItem pin) async {
    if (userId == null) return;
    final db = await _database;
    await db.insert(_table, {
      'ServerId': _serverId,
      'UserId': userId,
      'ItemId': pin.itemId,
      'ItemType': pin.kind.name,
      'Name': pin.name,
      'ImageUrl': pin.imageUrl?.toString(),
      'PinnedAt': pin.pinnedAt.toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> unpin(String itemId) async {
    if (userId == null) return;
    final db = await _database;
    await db.delete(
      _table,
      where: 'ServerId = ? AND UserId = ? AND ItemId = ?',
      whereArgs: [_serverId, userId, itemId],
    );
  }

  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_table, where: 'ServerId = ?', whereArgs: [_serverId]);
  }

  static PinnedItem _pinFromRow(Map<String, Object?> row) {
    final imageUrl = row['ImageUrl'] as String?;
    return (
      itemId: row['ItemId']! as String,
      kind: ItemKind.values.byName(row['ItemType']! as String),
      name: row['Name']! as String,
      imageUrl: imageUrl == null ? null : Uri.tryParse(imageUrl),
      pinnedAt: DateTime.fromMillisecondsSinceEpoch(
        row['PinnedAt']! as int,
        isUtc: true,
      ),
    );
  }
}
