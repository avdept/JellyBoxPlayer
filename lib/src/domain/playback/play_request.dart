import 'package:flutter/foundation.dart';
import 'package:jplayer/src/domain/models/models.dart';

abstract class RemotePlayback {
  Future<bool> play(PlayRequest request);

  Future<bool> enqueue(List<LibraryItem> songs, {required bool playNext});

  Future<bool> replaceUpcoming(
    List<LibraryItem> songs,
    LibraryItem album, {
    String? sourceId,
  });

  Future<bool> move(int from, int to);

  Future<bool> remove(int index);
}

@immutable
class PlayRequest {
  const PlayRequest({
    required this.song,
    required this.songs,
    required this.album,
    this.sourceId,
  });

  final LibraryItem song;
  final List<LibraryItem> songs;
  final LibraryItem album;
  final String? sourceId;

  int get index {
    final found = songs.indexWhere((candidate) => candidate.id == song.id);
    return found < 0 ? 0 : found;
  }

  List<String> get itemIds => [for (final item in songs) item.id];
}
