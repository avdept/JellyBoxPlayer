import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/car/car_content.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:mocktail/mocktail.dart';

import 'car_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CarContent.list', () {
    test('- reports hasMore only when a full page came back', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);

      env.stubAlbums(albums(CarContent.pageSize));
      var page = await content.list(type: 'albums');
      expect(page.entries, hasLength(CarContent.pageSize));
      expect(page.hasMore, isTrue);

      env.stubAlbums(albums(5));
      page = await content.list(type: 'albums', startIndex: 100);
      expect(page.entries, hasLength(5));
      expect(page.hasMore, isFalse);

      final queries = verify(() => env.client.getAlbums(captureAny())).captured;
      expect(queries.cast<LibraryQuery>().map((q) => q.startIndex), [0, 100]);
    });

    test('- follows the car sort filter', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);
      env.stubAlbums(const []);

      content.setSort('sortName');
      await content.list(type: 'albums');

      final query =
          verify(() => env.client.getAlbums(captureAny())).captured.single
              as LibraryQuery;
      expect(query.sort, ItemSort.name);
      expect(query.direction, SortDirection.ascending);
    });

    test('- accumulates song pages into the songs context', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);

      env.stubSongs([song('s1'), song('s2')]);
      await content.list(type: 'songs');
      env.stubSongs([song('s3')]);
      await content.list(type: 'songs', startIndex: 100);

      expect(
        content.songsIn(CarContent.songsContext).map((s) => s.id),
        ['s1', 's2', 's3'],
      );
    });

    test(
      '- returns nothing when signed out without touching the server',
      () async {
        final env = CarTestEnv(signedIn: false);
        final content = CarContent(env.container);

        final page = await content.list(type: 'albums');

        expect(page.entries, isEmpty);
        verifyNever(() => env.client.getAlbums(any()));
      },
    );
  });

  group('CarContent.search', () {
    test(
      '- shapes results and remembers songs as the search context',
      () async {
        final env = CarTestEnv();
        final content = CarContent(env.container);
        env.stubSearch(
          albums: [album('a1')],
          artists: [artist('ar1')],
          playlists: [playlist('p1')],
          songs: [song('s1'), song('s2')],
        );

        final results = await content.search(' foo ');

        expect(results.albums.single.id, 'a1');
        expect(results.artists.single.id, 'ar1');
        expect(results.playlists.single.id, 'p1');
        expect(results.songs.map((e) => e.id), ['s1', 's2']);
        expect(
          content.songsIn(CarContent.searchContext).map((s) => s.id),
          ['s1', 's2'],
        );
        final query =
            verify(() => env.client.searchAlbums(captureAny())).captured.single
                as SearchQuery;
        expect(query.term, 'foo');
      },
    );
  });

  group('CarContent.play', () {
    test('- routes cached items to the matching set playback', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);
      env
        ..stubAlbums([album('a1')])
        ..stubPlaylists([playlist('p1')])
        ..stubArtists([artist('ar1')]);
      await content.list(type: 'albums');
      await content.list(type: 'playlists');
      await content.list(type: 'artists');

      await content.play('album', 'a1');
      await content.play('playlist', 'p1');
      await content.play('artist', 'ar1');
      await content.play('mix', likedSongsPlaylistId);

      verify(() => env.setPlayback.playAlbum(album('a1'))).called(1);
      verify(() => env.setPlayback.playPlaylist(playlist('p1'))).called(1);
      verify(() => env.setPlayback.playArtist(artist('ar1'))).called(1);
      verify(
        () => env.setPlayback.playFavouriteSongs(likedSongsPlaylist),
      ).called(1);
      verifyNever(() => env.client.getItem(any(), kind: any(named: 'kind')));
    });

    test('- fetches an unknown id from the server before playing', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);
      when(
        () => env.client.getItem('a9', kind: ItemKind.album),
      ).thenAnswer((_) async => album('a9'));

      await content.play('album', 'a9');

      verify(() => env.setPlayback.playAlbum(album('a9'))).called(1);
    });

    test('- plays a song with the list it was shown in as the queue', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);
      env.stubSearch(songs: [song('s1'), song('s2')]);
      await content.search('foo');

      await content.play('song', 's2', songContext: CarContent.searchContext);

      final call = verify(
        () =>
            env.playbackNotifier.play(captureAny(), captureAny(), captureAny()),
      ).captured;
      expect((call[0] as LibraryItem).id, 's2');
      expect((call[1] as List<LibraryItem>).map((s) => s.id), ['s1', 's2']);
      expect((call[2] as LibraryItem).id, 'album-1');
    });

    test(
      '- falls back to a single-song queue when the context is stale',
      () async {
        final env = CarTestEnv();
        final content = CarContent(env.container);
        env.stubSearch(songs: [song('s1')]);
        await content.search('foo');
        when(
          () => env.client.getItem('s9', kind: ItemKind.song),
        ).thenAnswer((_) async => song('s9'));

        await content.play('song', 's9', songContext: CarContent.searchContext);

        final call = verify(
          () => env.playbackNotifier.play(
            captureAny(),
            captureAny(),
            captureAny(),
          ),
        ).captured;
        expect((call[1] as List<LibraryItem>).map((s) => s.id), ['s9']);
      },
    );
  });

  group('CarContent.contentChanged', () {
    test('- fires when the car sort changes', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);

      final changed = expectLater(content.contentChanged, emits(anything));
      content.setSort('random');

      await changed;
    });
  });
}
