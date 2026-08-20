import 'package:jplayer/src/domain/models/library_item/library_item.dart';

class GeneratedPlaylist {
  const GeneratedPlaylist({
    required this.item,
    required this.coverSongs,
    this.libraryId,
    this.remoteId,
    this.syncedAt,
  });

  final LibraryItem item;
  final List<LibraryItem> coverSongs;
  final String? libraryId;
  final String? remoteId;
  final DateTime? syncedAt;

  bool get isSynced => remoteId != null;
}
