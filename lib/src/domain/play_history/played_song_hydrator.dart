import 'dart:math';

import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/storages/play_history_database.dart';
import 'package:jplayer/src/domain/models/models.dart';

class PlayedSongHydrator {
  PlayedSongHydrator(
    this._history,
    this._client, {
    required bool Function() offline,
  }) : _offline = offline;

  static const batchSize = 100;

  final PlayHistoryDatabase _history;
  final MediaServerClient _client;
  final bool Function() _offline;

  Future<List<LibraryItem>> hydrate(List<String> ids) async {
    final stored = await _history.playedSongsByIds(ids);
    final missing = [
      for (final id in ids)
        if (!stored.containsKey(id)) id,
    ];
    final fetched = missing.isEmpty || _offline()
        ? const <String, LibraryItem>{}
        : await _fetch(missing);
    return [
      for (final id in ids) ?(stored[id] ?? fetched[id]),
    ];
  }

  Future<List<LibraryItem>> refresh(List<String> ids) async {
    if (ids.isEmpty) return const [];
    if (_offline()) return hydrate(ids);
    final Map<String, LibraryItem> fresh;
    try {
      fresh = await _fetch(ids);
    } on Object {
      return hydrate(ids);
    }
    return [
      for (final id in ids) ?fresh[id],
    ];
  }

  Future<Map<String, LibraryItem>> _fetch(List<String> ids) async {
    final batches = await Future.wait([
      for (var start = 0; start < ids.length; start += batchSize)
        _client.getItemsByIds(
          ids.sublist(start, min(start + batchSize, ids.length)),
        ),
    ]);
    final byId = <String, LibraryItem>{
      for (final batch in batches)
        for (final item in batch) item.id: item,
    };
    if (byId.isNotEmpty) await _history.saveSongs(byId.values);
    return byId;
  }
}
