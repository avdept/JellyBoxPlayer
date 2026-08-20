import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_playlist_generator.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  late MockMediaServerClient mockClient;

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() => mockClient = MockMediaServerClient());

  LibraryItem song(
    String id, {
    List<String> genres = const [],
    int plays = 0,
    String? album,
  }) => LibraryItem(
    id: id,
    name: id,
    kind: ItemKind.song,
    genres: genres,
    albumId: album,
    images: ImageRefs(albumPrimary: 'tag-$id'),
    userData: PlaybackUserData(playCount: plays, played: plays > 0),
  );

  /// A genre's songs spread over [albums] albums, [perAlbum] tracks each.
  LibraryPage pool(String genreId, {required int albums, int perAlbum = 3}) =>
      LibraryPage(
        items: [
          for (var a = 1; a <= albums; a++)
            for (var t = 1; t <= perAlbum; t++)
              song('$genreId-a$a-t$t', album: '$genreId-album-$a'),
        ],
        totalRecordCount: albums * perAlbum,
      );

  LibraryItem genre(String id, String name) =>
      LibraryItem(id: id, name: name, kind: ItemKind.genre);

  void stubScan(List<LibraryItem> songs) {
    when(
      () => mockClient.getAllSongs(
        userId: any(named: 'userId'),
        libraryId: any(named: 'libraryId'),
        startIndex: any(named: 'startIndex'),
        limit: any(named: 'limit'),
        sortBy: any(named: 'sortBy'),
        sortOrder: any(named: 'sortOrder'),
        filters: any(named: 'filters'),
        fields: any(named: 'fields'),
      ),
    ).thenAnswer((_) async => LibraryPage(items: songs));
  }

  void stubGenres(List<LibraryItem> genres) {
    when(
      () => mockClient.getGenres(
        userId: any(named: 'userId'),
        libraryId: any(named: 'libraryId'),
        startIndex: any(named: 'startIndex'),
        limit: any(named: 'limit'),
        sortBy: any(named: 'sortBy'),
        sortOrder: any(named: 'sortOrder'),
      ),
    ).thenAnswer((_) async => LibraryPage(items: genres));
  }

  void stubSongsOfSet(
    LibraryPage Function(List<String> genreIds, List<String> filters) respond,
  ) {
    when(
      () => mockClient.getSongsOfSet(
        userId: any(named: 'userId'),
        libraryId: any(named: 'libraryId'),
        artistIds: any(named: 'artistIds'),
        genreIds: any(named: 'genreIds'),
        filters: any(named: 'filters'),
        sortBy: any(named: 'sortBy'),
        sortOrder: any(named: 'sortOrder'),
        startIndex: any(named: 'startIndex'),
        limit: any(named: 'limit'),
        fields: any(named: 'fields'),
      ),
    ).thenAnswer((invocation) async {
      final args = invocation.namedArguments;
      return respond(
        args[const Symbol('genreIds')] as List<String>,
        args[const Symbol('filters')] as List<String>,
      );
    });
  }

  Future<List<GeneratedPlaylist>> generate({
    bool includeDiscovery = false,
    int seed = 1,
  }) => generateJellyfinTodaysPlaylists(
    mockClient,
    userId: 'user-1',
    includeDiscovery: includeDiscovery,
    random: Random(seed),
  );

  group('generateJellyfinTodaysPlaylists', () {
    test('- ranks genres by play count, gates on size, caps at 3', () async {
      stubScan([
        song('a', genres: ['Rock'], plays: 10),
        song('b', genres: ['Rock', 'Jazz'], plays: 5),
        song('c', genres: ['Pop'], plays: 8),
        song('d', genres: ['Metal'], plays: 7),
        song('e', genres: ['Blues'], plays: 6),
        song('f', genres: ['Folk'], plays: 1),
      ]);
      stubGenres([
        genre('rock-id', 'Rock'),
        genre('pop-id', 'Pop'),
        genre('metal-id', 'Metal'),
        genre('blues-id', 'Blues'),
        genre('jazz-id', 'Jazz'),
        genre('folk-id', 'Folk'),
      ]);

      const albumsPerGenre = {
        'rock-id': 12,
        'pop-id': 3,
        'metal-id': 10,
        'blues-id': 10,
        'jazz-id': 20,
      };
      stubSongsOfSet(
        (genreIds, filters) =>
            pool(genreIds.first, albums: albumsPerGenre[genreIds.first] ?? 0),
      );

      final playlists = await generate();

      expect(
        playlists.map((playlist) => playlist.item.name),
        ['Rock mix', 'Metal mix', 'Blues mix'],
      );
      expect(playlists.first.item.id, jellyfinGenreMixId(const ['rock-id']));
      expect(playlists.first.item.kind, ItemKind.playlist);
    });

    test('- merges spelling variants into one playlist', () async {
      stubScan([
        song('a', genres: ['Alt Metal'], plays: 6),
        song('b', genres: ['Alt. Metal'], plays: 5),
        song('c', genres: ['alt-metal'], plays: 4),
        song('d', genres: ['Pop'], plays: 12),
      ]);
      stubGenres([
        genre('alt-1', 'Alt Metal'),
        genre('alt-2', 'Alt. Metal'),
        genre('alt-3', 'alt-metal'),
        genre('pop-id', 'Pop'),
      ]);
      stubSongsOfSet((genreIds, filters) => pool(genreIds.first, albums: 12));

      final playlists = await generate();

      expect(playlists, hasLength(2));
      expect(playlists.first.item.name, 'Alt Metal mix');
      expect(
        jellyfinGenreIdsOf(playlists.first.item.id),
        ['alt-1', 'alt-2', 'alt-3'],
      );
    });

    test('- labels a merged genre with its most played spelling', () async {
      stubScan([
        song('a', genres: ['alt. metal'], plays: 2),
        song('b', genres: ['Alt Metal'], plays: 9),
      ]);
      stubGenres([genre('alt-1', 'alt. metal'), genre('alt-2', 'Alt Metal')]);
      stubSongsOfSet((genreIds, filters) => pool(genreIds.first, albums: 12));

      expect((await generate()).single.item.name, 'Alt Metal mix');
    });

    test('- yields nothing when no played song carries a genre', () async {
      stubScan([song('a', plays: 10), song('b', plays: 4)]);
      stubGenres([genre('rock-id', 'Rock')]);

      expect(await generate(), isEmpty);
      verifyNever(
        () => mockClient.getGenres(
          userId: any(named: 'userId'),
          libraryId: any(named: 'libraryId'),
          startIndex: any(named: 'startIndex'),
          limit: any(named: 'limit'),
          sortBy: any(named: 'sortBy'),
          sortOrder: any(named: 'sortOrder'),
        ),
      );
    });

    test('- skips genres the library has no matching item for', () async {
      stubScan([
        song('a', genres: ['Rock'], plays: 10),
      ]);
      stubGenres([genre('jazz-id', 'Jazz')]);
      stubSongsOfSet((genreIds, filters) => const LibraryPage());

      expect(await generate(), isEmpty);
    });
  });

  group('discovery playlists', () {
    void stubOneMainAndSpareGenres() {
      stubScan([
        song('a', genres: ['Rock'], plays: 10),
      ]);
      stubGenres([
        genre('rock-id', 'Rock'),
        genre('jazz-id', 'Jazz'),
        genre('dub-id', 'Dub'),
        genre('folk-id', 'Folk'),
        genre('opera-id', 'Opera'),
      ]);
      stubSongsOfSet((genreIds, filters) => pool(genreIds.first, albums: 12));
    }

    test('- are left out unless asked for', () async {
      stubOneMainAndSpareGenres();

      final playlists = await generate();

      expect(playlists.map((playlist) => playlist.item.name), ['Rock mix']);
    });

    test('- add two playlists from genres outside the play history', () async {
      stubOneMainAndSpareGenres();

      final playlists = await generate(includeDiscovery: true);

      expect(playlists, hasLength(3));
      expect(playlists.first.item.name, 'Rock mix');

      final discovery = playlists.skip(1).toList();
      expect(discovery, hasLength(2));
      for (final playlist in discovery) {
        expect(isJellyfinDiscoveryPlaylistId(playlist.item.id), isTrue);
        expect(playlist.item.name, startsWith('Discover '));
        expect(playlist.item.name, isNot(contains('Rock')));
      }
    });

    test('- never reuse a genre the listener already plays', () async {
      stubScan([
        song('a', genres: ['Rock'], plays: 10),
        song('b', genres: ['Jazz'], plays: 9),
        song('c', genres: ['Dub'], plays: 8),
        song('d', genres: ['Folk'], plays: 7),
      ]);
      stubGenres([
        genre('rock-id', 'Rock'),
        genre('jazz-id', 'Jazz'),
        genre('dub-id', 'Dub'),
        genre('folk-id', 'Folk'),
        genre('opera-id', 'Opera'),
      ]);
      stubSongsOfSet((genreIds, filters) => pool(genreIds.first, albums: 12));

      final playlists = await generate(includeDiscovery: true);
      final discovery = playlists
          .where((playlist) => isJellyfinDiscoveryPlaylistId(playlist.item.id))
          .toList();

      expect(discovery, hasLength(1));
      expect(discovery.single.item.name, 'Discover Opera');
    });

    test('- gate on unplayed songs, not total songs', () async {
      stubOneMainAndSpareGenres();
      stubSongsOfSet(
        (genreIds, filters) => filters.contains('IsUnplayed')
            ? pool(genreIds.first, albums: 2)
            : pool(genreIds.first, albums: 40),
      );

      final playlists = await generate(includeDiscovery: true);

      expect(
        playlists.every(
          (playlist) => !isJellyfinDiscoveryPlaylistId(playlist.item.id),
        ),
        isTrue,
      );
    });

    test('- still appear for a listener with no play history', () async {
      stubScan(const []);
      stubGenres([genre('jazz-id', 'Jazz'), genre('dub-id', 'Dub')]);
      stubSongsOfSet((genreIds, filters) => pool(genreIds.first, albums: 12));

      final playlists = await generate(includeDiscovery: true);

      expect(playlists, hasLength(2));
      expect(
        playlists.every(
          (playlist) => isJellyfinDiscoveryPlaylistId(playlist.item.id),
        ),
        isTrue,
      );
    });

    test('- vary between runs when there are spare genres', () async {
      stubScan([
        song('a', genres: ['Rock'], plays: 10),
      ]);
      stubGenres([
        genre('rock-id', 'Rock'),
        for (var i = 1; i <= 12; i++) genre('spare-$i', 'Spare $i'),
      ]);
      stubSongsOfSet((genreIds, filters) => pool(genreIds.first, albums: 12));

      final first = await generate(includeDiscovery: true, seed: 3);
      final second = await generate(includeDiscovery: true, seed: 7);

      expect(
        first.map((playlist) => playlist.item.name).toList(),
        isNot(second.map((playlist) => playlist.item.name).toList()),
      );
    });
  });

  group('fetchJellyfinGeneratedPlaylistSongs', () {
    test('- queries every genre id the playlist was built from', () async {
      stubSongsOfSet(
        (genreIds, filters) => LibraryPage(
          items: [for (final id in genreIds) song('song-$id', plays: 1)],
        ),
      );

      final songs = await fetchJellyfinGeneratedPlaylistSongs(
        mockClient,
        userId: 'user-1',
        playlistId: jellyfinGenreMixId(const ['alt-1', 'alt-2']),
        random: Random(1),
      );

      expect(
        songs.map((item) => item.id).toSet(),
        {'song-alt-1', 'song-alt-2'},
      );
    });

    test('- fills a discovery playlist with unplayed songs only', () async {
      var calls = 0;
      stubSongsOfSet((genreIds, filters) {
        calls++;
        expect(filters, ['IsUnplayed']);
        return LibraryPage(
          items: [for (var i = 1; i <= 30; i++) song('n$i')],
        );
      });

      final songs = await fetchJellyfinGeneratedPlaylistSongs(
        mockClient,
        userId: 'user-1',
        playlistId: jellyfinGenreDiscoveryId(const ['jazz-id']),
        random: Random(1),
      );

      expect(calls, 1);
      expect(songs, hasLength(20));
      expect(songs.every((item) => item.userData.playCount == 0), isTrue);
    });

    test('- refuses a playlist id it did not mint', () async {
      final songs = await fetchJellyfinGeneratedPlaylistSongs(
        mockClient,
        userId: 'user-1',
        playlistId: 'navidrome:something-else',
        random: Random(1),
      );

      expect(songs, isEmpty);
      verifyZeroInteractions(mockClient);
    });
  });
}
