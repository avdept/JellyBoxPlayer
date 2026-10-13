import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UnsafePathException implements Exception {
  const UnsafePathException(this.path, this.root);

  final String path;
  final String root;

  @override
  String toString() => 'UnsafePathException: $path escapes $root';
}

class DownloadPaths {
  DownloadPaths._();

  static const coverFileName = 'cover.jpg';
  static const musicDirectoryName = 'music';

  static final _safeSegment = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  static final _safeExtension = RegExp(r'^[a-z0-9]{1,8}$');
  static final _reservedNames = RegExp(
    r'^(con|prn|aux|nul|com[0-9]|lpt[0-9])$',
    caseSensitive: false,
  );

  static String? _root;

  static String? get root => _root;

  @visibleForTesting
  static set root(String? path) => _root = path;

  static Future<String> init() async {
    final existing = _root;
    if (existing != null) return existing;

    final documents = await getApplicationDocumentsDirectory();
    final musicDir = Directory(p.join(documents.path, musicDirectoryName));
    if (!musicDir.existsSync()) await musicDir.create(recursive: true);
    return _root = musicDir.path;
  }

  static String segment(String id) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (_safeSegment.hasMatch(id) && !_reservedNames.hasMatch(id)) return id;
    return sha256.convert(utf8.encode(id)).toString();
  }

  static String fileName(String id, String extension) {
    final normalized = extension.toLowerCase();
    if (!_safeExtension.hasMatch(normalized)) {
      throw ArgumentError.value(extension, 'extension', 'unsafe extension');
    }
    return '${segment(id)}.$normalized';
  }

  static String resolveWithin(String root, List<String> segments) {
    final path = p.normalize(p.joinAll([root, ...segments]));
    if (!p.isWithin(root, path)) throw UnsafePathException(path, root);
    return path;
  }

  static Future<bool> isResolvedWithinRoot(String path) async {
    final root = _root;
    if (root == null) return false;
    try {
      final realRoot = await Directory(root).resolveSymbolicLinks();
      final realPath = await Directory(path).resolveSymbolicLinks();
      return p.isWithin(realRoot, realPath);
    } on FileSystemException {
      return false;
    }
  }

  static String? albumDirectory(String albumId) {
    final root = _root;
    if (root == null) return null;
    if (albumId.isEmpty) {
      debugPrint('[Downloads] refusing empty album id');
      return null;
    }
    return resolveWithin(root, [segment(albumId)]);
  }

  static String? coverPath(String albumId) {
    final root = _root;
    if (root == null || albumId.isEmpty) return albumDirectory(albumId);
    return resolveWithin(root, [segment(albumId), coverFileName]);
  }

  static String? songPath(String albumId, String fileName) {
    final root = _root;
    if (root == null) return null;
    if (fileName.isEmpty || p.basename(fileName) != fileName) {
      throw ArgumentError.value(fileName, 'fileName', 'must be a bare name');
    }
    return resolveWithin(root, [segment(albumId), fileName]);
  }

  static File? coverFile(String? albumId) {
    if (albumId == null || albumId.isEmpty) return null;
    final path = coverPath(albumId);
    if (path == null) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  static Future<void> deleteAlbumDirectory(String albumId) async {
    final path = albumDirectory(albumId);
    if (path == null) return;
    final directory = Directory(path);
    if (!directory.existsSync()) return;
    if (!await isResolvedWithinRoot(path)) {
      debugPrint('[Downloads] refusing to delete $path outside $_root');
      return;
    }
    await directory.delete(recursive: true);
  }
}
