import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';

final AutoDisposeStateProviderFamily<String, String>
playlistSearchQueryProvider = StateProvider.autoDispose.family<String, String>(
  (ref, id) => '',
);

List<LibraryItem> filterSongsByQuery(List<LibraryItem> songs, String query) {
  final terms = query.toLowerCase().split(RegExp(r'\s+'))
    ..removeWhere((term) => term.isEmpty);
  if (terms.isEmpty) return songs;
  return [
    for (final song in songs)
      if (_matches(song, terms)) song,
  ];
}

bool _matches(LibraryItem song, List<String> terms) {
  final haystack = [
    song.name,
    song.artistLabel,
    song.albumName ?? '',
  ].join(' ').toLowerCase();
  return terms.every(haystack.contains);
}
