import 'package:jplayer/src/domain/models/library_item/library_item.dart';

class DownloadedSong {
  const DownloadedSong({
    required this.item,
    required this.filePath,
    required this.sizeInBytes,
    required this.downloadDate,
  });

  final LibraryItem item;
  final String filePath;
  final int sizeInBytes;
  final DateTime downloadDate;
}

class DownloadedAlbum {
  const DownloadedAlbum({
    required this.item,
    required this.sizeInBytes,
    required this.downloadDate,
  });

  final LibraryItem item;
  final int sizeInBytes;
  final DateTime downloadDate;
}
