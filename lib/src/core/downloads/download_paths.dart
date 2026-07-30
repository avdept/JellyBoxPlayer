import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DownloadPaths {
  DownloadPaths._();

  static const coverFileName = 'cover.jpg';

  static String? _root;

  static String? get root => _root;

  static Future<String> init() async {
    final existing = _root;
    if (existing != null) return existing;

    final documents = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${documents.path}/music');
    if (!musicDir.existsSync()) await musicDir.create(recursive: true);
    return _root = musicDir.path;
  }

  static String? albumDirectory(String albumId) {
    final root = _root;
    return (root == null) ? null : '$root/$albumId';
  }

  static String? coverPath(String albumId) {
    final directory = albumDirectory(albumId);
    return (directory == null) ? null : '$directory/$coverFileName';
  }

  static File? coverFile(String? albumId) {
    if (albumId == null) return null;
    final path = coverPath(albumId);
    if (path == null) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  static Future<void> deleteAlbumDirectory(String albumId) async {
    final path = albumDirectory(albumId);
    if (path == null) return;
    final directory = Directory(path);
    if (directory.existsSync()) await directory.delete(recursive: true);
  }
}
