import 'package:genre_playlists/src/song_traits.dart';

enum SongPool { any, played, unplayed }

enum SongOrder { random, mostPlayed }

class GenreRef {
  const GenreRef({required this.id, required this.name});

  final String id;
  final String name;
}

abstract class GenrePlaylistSource<S> implements SongTraits<S> {
  Future<List<S>> mostPlayedSongs({required int limit});

  Future<List<GenreRef>> genres({required int limit});

  Future<List<S>> genreSongs(
    List<String> genreIds, {
    required SongPool pool,
    required SongOrder order,
    required int limit,
    required bool forPlayback,
  });
}
