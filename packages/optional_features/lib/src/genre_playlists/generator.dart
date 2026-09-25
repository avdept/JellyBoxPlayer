import 'dart:math';

import 'package:optional_features/src/genre_playlists/playlist_id.dart';
import 'package:optional_features/src/genre_playlists/source.dart';

class GeneratedPlaylistSpec<S> {
  const GeneratedPlaylistSpec({
    required this.id,
    required this.name,
    required this.coverSongs,
  });

  final String id;
  final String name;
  final List<S> coverSongs;

  bool get isDiscovery => isDiscoveryPlaylistId(id);
}

class GenrePlaylistGenerator<S> {
  GenrePlaylistGenerator(this.source, {Random? random})
    : random = random ?? Random();

  final GenrePlaylistSource<S> source;
  final Random random;

  Future<List<GeneratedPlaylistSpec<S>>> generate({
    bool includeDiscovery = false,
  }) async => const [];

  Future<List<S>> songsFor(String playlistId) async => const [];
}
