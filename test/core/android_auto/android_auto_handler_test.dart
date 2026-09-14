import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/android_auto/android_auto_handler.dart';
import 'package:jplayer/src/core/android_auto/auto_media_id.dart';
import 'package:jplayer/src/core/car/car_content.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../car/car_test_fixtures.dart';

const _group = 'android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT';
const _playableHint = 'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  (CarTestEnv, AndroidAutoHandler) build({
    bool signedIn = true,
    bool offline = false,
    List<GeneratedPlaylist> mixes = const [],
    List<LibraryItem> favouriteSongs = const [],
    List<DownloadedAlbum> downloads = const [],
    PlaybackState? playback,
  }) {
    final env = CarTestEnv(
      signedIn: signedIn,
      offline: offline,
      mixes: mixes,
      favouriteSongs: favouriteSongs,
      downloads: downloads,
      playback: playback,
    );
    return (env, AndroidAutoHandler(env.container, CarContent(env.container)));
  }

  group('root', () {
    test('- asks to sign in when there is no user', () async {
      final (_, handler) = build(signedIn: false);

      final children = await handler.getChildren(AutoMediaId.root);

      expect(children.single.id, AutoMediaId.signIn);
      expect(children.single.playable, isTrue);
    });

    test('- offers only Downloads while offline', () async {
      final (_, handler) = build(offline: true);

      final children = await handler.getChildren(AutoMediaId.root);

      expect(children.map((c) => c.id), [AutoMediaId.downloads]);
    });

    test('- offers Home, Library and Downloads tabs', () async {
      final (_, handler) = build();

      final children = await handler.getChildren(AutoMediaId.root);

      expect(children.map((c) => c.id), [
        AutoMediaId.home,
        AutoMediaId.library,
        AutoMediaId.downloads,
      ]);
      expect(children.every((c) => c.playable != true), isTrue);
    });
  });

  group('home', () {
    test('- groups mixes before recently added albums', () async {
      const mix = GeneratedPlaylist(
        item: LibraryItem(
          id: 'jellybox:genre-mix:rock',
          name: 'Rock mix',
          kind: ItemKind.playlist,
        ),
        coverSongs: [],
      );
      final (env, _) = build(
        mixes: [mix],
        favouriteSongs: [song('fav')],
      );
      env.stubAlbums([album('a1')]);
      final content = CarContent(env.container);
      final auto = AndroidAutoHandler(env.container, content);
      final refreshed = expectLater(auto.childrenChanged, emits(isNull));

      final firstLoad = await auto.getChildren(AutoMediaId.home);
      expect(firstLoad.map((c) => c.id), [
        'mix/jellybox%3Agenre-mix%3Arock',
        'album/a1',
      ]);
      await refreshed;
      final children = await auto.getChildren(AutoMediaId.home);

      expect(children.map((c) => c.id), [
        'mix/jellybox%3Agenre-mix%3Arock',
        'mix/jellybox%3Aliked-songs',
        'album/a1',
      ]);
      expect(children[0].extras?[_group], 'Made for you');
      expect(children[1].extras?[_group], 'Made for you');
      expect(children[2].extras?[_group], 'Recently added');
      expect(children.every((c) => c.playable == true), isTrue);
    });
  });

  group('library lists', () {
    test('- library lists the four browse folders', () async {
      final (_, handler) = build();

      final children = await handler.getChildren(AutoMediaId.library);

      expect(children.map((c) => c.id), [
        AutoMediaId.albums,
        AutoMediaId.artists,
        AutoMediaId.playlists,
        AutoMediaId.songs,
      ]);
    });

    test('- appends Load more only when the page is full', () async {
      final (env, handler) = build();

      env.stubAlbums(albums(CarContent.pageSize));
      var children = await handler.getChildren(AutoMediaId.albums);
      expect(children, hasLength(CarContent.pageSize + 1));
      expect(children.last.id, 'albums?start=100');
      expect(children.last.playable, isFalse);
      expect(children.first.id, 'album/album-0');

      env.stubAlbums(albums(3));
      children = await handler.getChildren('albums?start=100');
      expect(children, hasLength(3));
      expect(children.any((c) => c.title == 'Load more…'), isFalse);
    });

    test('- songs carry the songs context', () async {
      final (env, handler) = build();
      env.stubSongs([song('s1')]);

      final children = await handler.getChildren(AutoMediaId.songs);

      expect(children.single.id, 'song/s1?ctx=songs');
      expect(children.single.album, 'Album album-1');
      expect(children.single.duration, const Duration(minutes: 3));
    });

    test('- artists are folders that open Play all plus albums', () async {
      final (env, handler) = build();
      env
        ..stubArtists([artist('ar1')])
        ..stubAlbums([album('a1'), album('a2')]);

      final artists = await handler.getChildren(AutoMediaId.artists);
      expect(artists.single.id, 'artist/ar1');
      expect(artists.single.playable, isFalse);
      expect(artists.single.extras?[_playableHint], 2);

      final children = await handler.getChildren('artist/ar1');
      expect(children.map((c) => c.id), [
        'artist/ar1/all',
        'album/a1',
        'album/a2',
      ]);
      expect(children.first.title, 'Play all');
      expect(children.first.artist, 'Artist ar1');
    });

    test('- downloads list offline albums', () async {
      final (_, handler) = build(
        downloads: [
          DownloadedAlbum(
            item: album('d1'),
            sizeInBytes: 1,
            downloadDate: DateTime(2026),
          ),
        ],
      );

      final children = await handler.getChildren(AutoMediaId.downloads);

      expect(children.single.id, 'download/d1');
      expect(children.single.playable, isTrue);
    });
  });

  group('recent root', () {
    test('- exposes the current track as a resume item', () async {
      final (env, handler) = build(
        playback: playbackState([song('s1'), song('s2')], 1),
      );

      final children = await handler.getChildren(AutoMediaId.recent);
      expect(children.single.id, AutoMediaId.resume);
      expect(children.single.title, 'Song s2');

      await handler.playFromMediaId(AutoMediaId.resume);
      verify(() => env.playbackNotifier.resume()).called(1);
    });

    test('- is empty without a queue', () async {
      final (_, handler) = build();

      expect(await handler.getChildren(AutoMediaId.recent), isEmpty);
    });
  });

  group('playFromMediaId', () {
    test('- routes sets to the matching playback method', () async {
      final (env, handler) = build(favouriteSongs: [song('fav')]);
      env
        ..stubAlbums([album('a1')])
        ..stubPlaylists([playlist('p1')])
        ..stubArtists([artist('ar1')]);
      await handler.getChildren(AutoMediaId.albums);
      await handler.getChildren(AutoMediaId.playlists);
      await handler.getChildren(AutoMediaId.artists);
      await settle();

      await handler.playFromMediaId('album/a1');
      await handler.playFromMediaId('playlist/p1');
      await handler.playFromMediaId('artist/ar1/all');
      await handler.playFromMediaId('mix/jellybox%3Aliked-songs');
      await handler.playFromMediaId(AutoMediaId.signIn);
      await handler.playFromMediaId('garbage');

      verify(() => env.setPlayback.playAlbum(album('a1'))).called(1);
      verify(() => env.setPlayback.playPlaylist(playlist('p1'))).called(1);
      verify(() => env.setPlayback.playArtist(artist('ar1'))).called(1);
      verify(
        () => env.setPlayback.playFavouriteSongs(likedSongsPlaylist),
      ).called(1);
    });

    test('- plays a searched song with the search results as queue', () async {
      final (env, handler) = build();
      env.stubSearch(songs: [song('s1'), song('s2')]);
      final results = await handler.search('foo');
      expect(results.map((c) => c.id), [
        'song/s1?ctx=search',
        'song/s2?ctx=search',
      ]);
      expect(results.first.extras?[_group], 'Songs');

      await handler.playFromMediaId(results.last.id);

      final call = verify(
        () =>
            env.playbackNotifier.play(captureAny(), captureAny(), captureAny()),
      ).captured;
      expect((call[0] as LibraryItem).id, 's2');
      expect((call[1] as List<LibraryItem>).map((s) => s.id), ['s1', 's2']);
    });
  });

  group('playFromSearch', () {
    test('- honours the artist focus hint', () async {
      final (env, handler) = build();
      env.stubSearch(artists: [artist('ar1')], albums: [album('a1')]);

      await handler.playFromSearch('anything', {
        'android.intent.extra.focus': 'vnd.android.cursor.item/artist',
      });

      verify(() => env.setPlayback.playArtist(artist('ar1'))).called(1);
      verifyNever(() => env.setPlayback.playAlbum(any()));
    });

    test('- prefers an exact album title over the first song', () async {
      final (env, handler) = build();
      env.stubSearch(albums: [album('a1')], songs: [song('s1')]);

      await handler.playFromSearch('album A1');

      verify(() => env.setPlayback.playAlbum(album('a1'))).called(1);
      verifyNever(() => env.playbackNotifier.play(any(), any(), any()));
    });

    test('- falls back to the first song', () async {
      final (env, handler) = build();
      env.stubSearch(albums: [album('a1')], songs: [song('s1')]);

      await handler.playFromSearch('something else');

      final call = verify(
        () =>
            env.playbackNotifier.play(captureAny(), captureAny(), captureAny()),
      ).captured;
      expect((call[0] as LibraryItem).id, 's1');
    });

    test('- resumes the queue for an empty query', () async {
      final (env, handler) = build(playback: playbackState([song('s1')], 0));

      await handler.playFromSearch('');

      verify(() => env.playbackNotifier.resume()).called(1);
      verifyNever(() => env.client.searchSongs(any()));
    });
  });

  group('childrenChanged', () {
    test('- emits for every parent when the car sort changes', () async {
      final (env, handler) = build();
      final content = CarContent(env.container);
      final auto = AndroidAutoHandler(env.container, content);

      final changed = expectLater(auto.childrenChanged, emits(isNull));
      content.setSort('sortName');

      await changed;
      expect(handler, isNotNull);
    });
  });

  group('artwork', () {
    test('- rewrites downloaded covers to the content provider', () {
      final rewritten = AndroidAutoHandler.autoArtUri(
        Uri.file(
          '/data/user/0/com.prodigytech.jellybox/app_flutter/music/ab12/cover.jpg',
        ),
      );
      expect(
        rewritten.toString(),
        'content://${AndroidAutoHandler.coverAuthority}/ab12',
      );
    });

    test('- leaves server urls alone', () {
      final uri = Uri.parse('https://jf.example/Items/1/Images/Primary');
      expect(AndroidAutoHandler.autoArtUri(uri), same(uri));
      expect(AndroidAutoHandler.autoArtUri(null), isNull);
    });
  });
}
