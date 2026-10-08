import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:sqflite/sqflite.dart';

typedef AnimatedCoverEntry = ({Uri? url, DateTime checkedAt});

class AnimatedCoverDatabase {
  AnimatedCoverDatabase(this._owner);

  static const _table = 'AnimatedCovers';

  final DownloadDatabase _owner;

  static String keyFor({required String artist, required String album}) =>
      '${artist.trim().toLowerCase()}\n${album.trim().toLowerCase()}';

  Future<AnimatedCoverEntry?> get(String key) async {
    final db = await _owner.database;
    final rows = await db.query(
      _table,
      where: 'Key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final url = row['Url'] as String?;
    return (
      url: url == null ? null : Uri.tryParse(url),
      checkedAt: DateTime.fromMicrosecondsSinceEpoch(row['CheckedAt']! as int),
    );
  }

  Future<void> put(String key, Uri? url) async {
    final db = await _owner.database;
    await db.insert(_table, {
      'Key': key,
      'Url': url?.toString(),
      'CheckedAt': DateTime.now().microsecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
