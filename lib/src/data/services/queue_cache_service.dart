import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/downloads/cache_downloader.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/services/album_cover_store.dart';
import 'package:jplayer/src/data/storages/queue_cache_database.dart';
import 'package:jplayer/src/domain/models/models.dart';

class QueueCacheService {
  QueueCacheService({
    required QueueCacheDatabase database,
    required CacheDownloader downloader,
    required String deviceId,
    AlbumCoverStore? covers,
  }) : _database = database,
       _downloader = downloader,
       _deviceId = deviceId,
       _covers = covers ?? AlbumCoverStore();

  static const _coverSize = 512;

  final QueueCacheDatabase _database;
  final CacheDownloader _downloader;
  final String _deviceId;
  final AlbumCoverStore _covers;

  Future<String?> cache(LibraryItem song, MediaServerClient client) async {
    try {
      final resolved = await client.resolveStreamSource(
        song,
        playSessionId: 'cache-$_deviceId-${song.id}',
        target: StreamTargetProfile.download(),
      );
      final path = await _downloader.fetch(
        id: song.id,
        url: resolved.uri.toString(),
        fileName: '${song.id}.${resolved.outputContainer}',
      );
      if (path == null) return null;
      final file = File(path);
      if (!file.existsSync() || file.lengthSync() == 0) {
        if (file.existsSync()) await file.delete();
        return null;
      }
      await _database.insert(song, file: file);
      await _cacheCover(song, client);
      debugPrint('[QueueCache] cached "${song.name}"');
      return path;
    } on Object catch (error) {
      debugPrint('[QueueCache] "${song.name}" failed: $error');
      return null;
    }
  }

  Future<void> _cacheCover(LibraryItem song, MediaServerClient client) async {
    final albumId = song.albumId;
    if (albumId == null) return;
    try {
      await _covers.ensure(
        albumId,
        client.imageUri(song, kind: ImageKind.album, size: _coverSize),
      );
    } on Object catch (error) {
      debugPrint('[QueueCache] cover for "${song.name}" failed: $error');
    }
  }

  Future<void> cancel(String id) async {
    try {
      await _downloader.cancel(id);
    } on Object catch (error) {
      debugPrint('[QueueCache] cancelling $id failed: $error');
    }
  }

  Future<void> enforceLimit(
    int limitBytes, {
    Set<String> keepIds = const {},
  }) async {
    var used = await _database.totalBytes();
    if (used <= limitBytes) return;
    for (final entry in await _database.leastRecentlyUsed(
      excludedIds: keepIds,
    )) {
      if (used <= limitBytes) break;
      await _database.delete(entry.id);
      used -= entry.sizeInBytes;
    }
  }

  Future<void> purge() async {
    await _database.deleteAll();
    await _deleteOrphanFiles();
  }

  Future<void> reconcile() async {
    await _database.deleteForeignServers();
    await _database.pruneMissing();
    await _deleteOrphanFiles();
    await _sweepCovers();
  }

  Future<void> _sweepCovers() async {
    try {
      final entries = await _database.detailedEntries();
      await _covers.sweepUnreferenced({
        for (final entry in entries)
          if (entry.item.albumId case final String albumId) albumId,
      });
    } on Object catch (error) {
      debugPrint('[QueueCache] sweeping covers failed: $error');
    }
  }

  Future<int> pruneMissing() => _database.pruneMissing();

  Future<void> _deleteOrphanFiles() async {
    try {
      final directory = Directory(await _downloader.directoryPath());
      if (!directory.existsSync()) return;
      final known = await _database.allFilePaths();
      for (final file in directory.listSync().whereType<File>()) {
        if (!known.contains(file.path)) await file.delete();
      }
    } on Object catch (error) {
      debugPrint('[QueueCache] sweeping stray files failed: $error');
    }
  }
}
