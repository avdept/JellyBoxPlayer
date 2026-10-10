import 'package:optional_features/genre_playlists.dart';
import 'package:test/test.dart';

class _NoSource implements GenrePlaylistSource<String> {
  @override
  String idOf(String song) => song;

  @override
  String? albumIdOf(String song) => null;

  @override
  List<String> genresOf(String song) => const [];

  @override
  int playCountOf(String song) => 0;

  @override
  bool hasCoverOf(String song) => false;

  @override
  Future<List<String>> mostPlayedSongs({required int limit}) =>
      throw StateError('the stub must not query the source');

  @override
  Future<List<GenreRef>> genres({required int limit}) =>
      throw StateError('the stub must not query the source');

  @override
  Future<List<String>> genreSongs(
    List<String> genreIds, {
    required SongPool pool,
    required SongOrder order,
    required int limit,
    required bool forPlayback,
  }) => throw StateError('the stub must not query the source');
}

void main() {
  group('playlist ids', () {
    test('- round-trip genre ids with commas, slashes and spaces', () {
      final genres = ['Hip-Hop/Rap', 'R&B, Soul', 'Heavy Metal'];

      final mix = genreMixId(genres);
      final discovery = genreDiscoveryId(genres);

      expect(isGeneratedPlaylistId(mix), isTrue);
      expect(isDiscoveryPlaylistId(mix), isFalse);
      expect(isDiscoveryPlaylistId(discovery), isTrue);
      expect(genreIdsOf(mix), genres);
      expect(genreIdsOf(discovery), genres);
    });

    test('- leave plain ids readable and reject foreign ones', () {
      expect(
        genreMixId(['rock-id', 'metal-id']),
        'jellybox:genre-mix:rock-id,metal-id',
      );
      expect(isGeneratedPlaylistId('jellybox:liked-songs'), isFalse);
    });

    test('- carry the moment they were made and still yield their genres', () {
      final at = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final stamped = genreMixId(['rock-id', '1990'], at: at);

      expect(stamped, 'jellybox:genre-mix:rock-id,1990:1700000000000');
      expect(genreIdsOf(stamped), ['rock-id', '1990']);
      expect(generatedPlaylistCreatedAt(stamped), at);
      expect(genreIdsOf(genreMixId(['1990'])), ['1990']);
      expect(generatedPlaylistCreatedAt(genreMixId(['1990'])), isNull);
    });
  });

  group('stub generator', () {
    test('- produces no playlists and touches no data', () async {
      final generator = GenrePlaylistGenerator<String>(_NoSource());

      expect(await generator.generate(includeDiscovery: true), isEmpty);
      expect(await generator.songsFor(genreMixId(['rock'])), isEmpty);
    });
  });
}
