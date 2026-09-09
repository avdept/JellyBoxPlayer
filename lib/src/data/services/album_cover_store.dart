import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';

typedef CoverFetcher = Future<List<int>?> Function(Uri uri);

class AlbumCoverStore {
  AlbumCoverStore({CoverFetcher? fetch}) : _fetch = fetch ?? _fetchOverHttp;

  final CoverFetcher _fetch;

  Future<File?> ensure(String albumId, Uri? uri) async {
    if (uri == null) return null;
    await DownloadPaths.init();
    final path = DownloadPaths.coverPath(albumId);
    if (path == null) return null;

    final file = File(path);
    if (file.existsSync() && file.lengthSync() > 0) return file;

    try {
      final bytes = await _fetch(uri);
      if (bytes == null || bytes.isEmpty) return null;
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return file;
    } on Object catch (error) {
      debugPrint('[Covers] cover for $albumId failed: $error');
      if (file.existsSync()) await file.delete();
      return null;
    }
  }

  Future<void> sweepUnreferenced(Set<String> keepAlbumIds) async {
    final root = DownloadPaths.root;
    if (root == null) return;
    final directory = Directory(root);
    if (!directory.existsSync()) return;

    for (final entry in directory.listSync().whereType<Directory>()) {
      final albumId = entry.path.split(Platform.pathSeparator).last;
      if (keepAlbumIds.contains(albumId)) continue;
      final contents = entry.listSync().whereType<File>().toList();
      if (contents.isEmpty) continue;
      final onlyCover = contents.every(
        (file) =>
            file.path.split(Platform.pathSeparator).last ==
            DownloadPaths.coverFileName,
      );
      if (onlyCover) await entry.delete(recursive: true);
    }
  }

  static Future<List<int>?> _fetchOverHttp(Uri uri) async {
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(uri)).close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return null;
      }
      final chunks = await response.toList();
      return [for (final chunk in chunks) ...chunk];
    } finally {
      client.close(force: true);
    }
  }
}
