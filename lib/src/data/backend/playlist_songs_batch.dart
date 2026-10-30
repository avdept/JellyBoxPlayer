import 'package:jplayer/src/domain/models/models.dart';

class PlaylistSongsBatch {
  const PlaylistSongsBatch({required this.songs, this.expectedTotal});

  final List<LibraryItem> songs;
  final int? expectedTotal;
}
