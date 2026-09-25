import 'package:flutter_test/flutter_test.dart';
import 'package:optional_features/genre_playlists.dart';
import 'package:jplayer/src/data/backend/genre_playlists.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  late MockMediaServerClient client;
  late MediaServerGenreSource source;

  setUpAll(() {
    registerFallbackValue(const LibraryQuery());
  });

  setUp(() {
    client = MockMediaServerClient();
    source = MediaServerGenreSource(client, libraryId: 'lib-1');
  });

  LibraryItem song(
    String id, {
    String? album,
    int plays = 0,
    bool art = false,
  }) => LibraryItem(
    id: id,
    name: id,
    kind: ItemKind.song,
    albumId: album,
    genres: const ['Rock'],
    images: art ? const ImageRefs(primary: 'tag') : const ImageRefs(),
    userData: PlaybackUserData(playCount: plays, played: plays > 0),
  );

  LibraryQuery captured(Function() call) =>
      verify(call).captured.single as LibraryQuery;

  test('exposes the song fields the policy reads', () {
    final item = song('s1', album: 'a1', plays: 3, art: true);

    expect(source.idOf(item), 's1');
    expect(source.albumIdOf(item), 'a1');
    expect(source.genresOf(item), ['Rock']);
    expect(source.playCountOf(item), 3);
    expect(source.hasCoverOf(item), isTrue);
    expect(source.hasCoverOf(song('s2')), isFalse);
  });

  test(
    'most played songs scan played songs by play count with genres',
    () async {
      when(() => client.getAllSongs(any())).thenAnswer(
        (_) async => LibraryPage(items: [song('s1', plays: 2)]),
      );

      final songs = await source.mostPlayedSongs(limit: 200);

      expect(songs.map((s) => s.id), ['s1']);
      final query = captured(() => client.getAllSongs(captureAny()));
      expect(query.libraryId, 'lib-1');
      expect(query.sort, ItemSort.playCount);
      expect(query.direction, SortDirection.descending);
      expect(query.filters, {ItemFilterFlag.played});
      expect(query.fields, {ItemField.genres});
      expect(query.limit, 200);
    },
  );

  test('genres come from the library genre list', () async {
    when(() => client.getGenres(any())).thenAnswer(
      (_) async => const LibraryPage(
        items: [LibraryItem(id: 'g1', name: 'Rock', kind: ItemKind.genre)],
      ),
    );

    final genres = await source.genres(limit: 500);

    expect(genres.single.id, 'g1');
    expect(genres.single.name, 'Rock');
    final query = captured(() => client.getGenres(captureAny()));
    expect(query.libraryId, 'lib-1');
    expect(query.limit, 500);
  });

  group('genre songs', () {
    setUp(() {
      when(() => client.getSongsOfSet(any())).thenAnswer(
        (_) async => LibraryPage(items: [song('s1')]),
      );
    });

    test('- probes ask for a random sample without heavy fields', () async {
      await source.genreSongs(
        ['g1', 'g2'],
        pool: SongPool.any,
        order: SongOrder.random,
        limit: 40,
        forPlayback: false,
      );

      final query = captured(() => client.getSongsOfSet(captureAny()));
      expect(query.libraryId, 'lib-1');
      expect(query.genreIds, ['g1', 'g2']);
      expect(query.filters, isEmpty);
      expect(query.sort, ItemSort.random);
      expect(query.fields, isEmpty);
      expect(query.limit, 40);
    });

    test('- playback fetches keep the default fields', () async {
      await source.genreSongs(
        ['g1'],
        pool: SongPool.played,
        order: SongOrder.mostPlayed,
        limit: 60,
        forPlayback: true,
      );

      final query = captured(() => client.getSongsOfSet(captureAny()));
      expect(query.filters, {ItemFilterFlag.played});
      expect(query.sort, ItemSort.playCount);
      expect(query.direction, SortDirection.descending);
      expect(query.fields, const LibraryQuery().fields);
      expect(query.limit, 60);
    });

    test('- unplayed pools map to the unplayed filter', () async {
      await source.genreSongs(
        ['g1'],
        pool: SongPool.unplayed,
        order: SongOrder.random,
        limit: 60,
        forPlayback: true,
      );

      final query = captured(() => client.getSongsOfSet(captureAny()));
      expect(query.filters, {ItemFilterFlag.unplayed});
      expect(query.sort, ItemSort.random);
    });
  });

  test(
    'wrappers turn specs into playlist items and never parse foreign ids',
    () async {
      final songs = await fetchGenrePlaylistSongs(
        client,
        playlistId: 'jellybox:liked-songs',
      );

      expect(songs, isEmpty);
      verifyNever(() => client.getSongsOfSet(any()));
    },
  );
}
