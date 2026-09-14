import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/android_auto/android_auto_handler.dart';
import 'package:jplayer/src/core/android_auto/auto_media_id.dart';
import 'package:jplayer/src/core/car/car_content.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:just_audio_background/just_audio_background.dart';
import 'package:mocktail/mocktail.dart';

import '../car/car_test_fixtures.dart';

const _group = 'android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT';
const _playableHint = 'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT';
const _browsableHint = 'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  (CarTestEnv, AndroidAutoHandler) build({
    bool signedIn = true,
    bool offline = false,
    List<GeneratedPlaylist> mixes = const [],
    List<LibraryItem> favouriteSongs = const [],
    List<LibraryItem> favouriteAlbums = const [],
    List<DownloadedAlbum> downloads = const [],
    PlaybackState? playback,
  }) {
    final env = CarTestEnv(
      signedIn: signedIn,
      offline: offline,
      mixes: mixes,
      favouriteSongs: favouriteSongs,
      favouriteAlbums: favouriteAlbums,
      downloads: downloads,
      playback: playback,
    );
    return (env, AndroidAutoHandler(env.container, CarContent(env.container)));
  }

  group('root extras', () {
    test('- enable search and keep the default list/grid styles', () {
      expect(
        AndroidAutoHandler.rootExtras['android.media.browse.SEARCH_SUPPORTED'],
        isTrue,
      );
      expect(AndroidAutoHandler.rootExtras[_browsableHint], 1);
      expect(AndroidAutoHandler.rootExtras[_playableHint], 2);
    });
  });

  group('search', () {
    test(
      '- groups artists, albums and playlists as folders, songs playable',
      () async {
        final (env, handler) = build();
        env.stubSearch(
          artists: [artist('ar1')],
          albums: [album('a1')],
          playlists: [playlist('p1')],
          songs: [song('s1')],
        );

        final results = await handler.search('foo');

        expect(results.map((c) => c.id), [
          'artist/ar1',
          'album/a1',
          'playlist/p1',
          'song/s1?ctx=search',
        ]);
        expect(results.map((c) => c.playable == true), [
          false,
          false,
          false,
          true,
        ]);
        expect(results.map((c) => c.extras?[_group]), [
          'Artists',
          'Albums',
          'Playlists',
          'Songs',
        ]);
        expect(results.map((c) => c.artist), [
          'Artist',
          'Album',
          'Playlist',
          'Song • Artist',
        ]);
      },
    );
  });

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
      expect(children.first.extras?[_browsableHint], 2);
      expect(children.last.extras?[_browsableHint], 2);
    });
  });

  group('home', () {
    test('- shows recently added in server order, capped at eight', () async {
      final (env, handler) = build();
      env
        ..stubAlbums(albums(12))
        ..stubPlaylists(const []);

      final children = await handler.getChildren(AutoMediaId.home);

      expect(children.map((c) => c.id), [
        for (var i = 0; i < 8; i++) 'album/album-$i',
      ]);
      expect(
        children.every((c) => c.extras?[_group] == 'Recently added'),
        isTrue,
      );
      final query =
          verify(() => env.client.getAlbums(captureAny())).captured.single
              as LibraryQuery;
      expect(query.limit, 8);
      expect(query.sort, ItemSort.dateCreated);
    });

    test(
      '- lists recently added, mixes, playlists and favourites in order',
      () async {
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
          favouriteAlbums: [album('fav-1'), album('fav-2')],
        );
        env
          ..stubAlbums([album('a1')])
          ..stubPlaylists([playlist('p1'), playlist('p2')]);
        final content = CarContent(env.container);
        final auto = AndroidAutoHandler(env.container, content);
        final refreshed = expectLater(auto.childrenChanged, emits(isNull));

        final firstLoad = await auto.getChildren(AutoMediaId.home);
        expect(firstLoad.map((c) => c.id), [
          'album/a1',
          'mix/jellybox%3Agenre-mix%3Arock',
          'playlist/p1',
          'playlist/p2',
        ]);
        await refreshed;
        final children = await auto.getChildren(AutoMediaId.home);

        expect(children.map((c) => c.id), [
          'album/a1',
          'mix/jellybox%3Agenre-mix%3Arock',
          'mix/jellybox%3Aliked-songs',
          'playlist/p1',
          'playlist/p2',
          'album/fav-1',
          'album/fav-2',
        ]);
        expect(children.map((c) => c.extras?[_group]), [
          'Recently added',
          'Made for you',
          'Made for you',
          'Playlists',
          'Playlists',
          'Favourites',
          'Favourites',
        ]);
        expect(children.every((c) => c.playable != true), isTrue);
      },
    );
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
      expect(artists.single.extras?[_browsableHint], 2);

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
      expect(children.single.playable, isFalse);
    });
  });

  group('set pages', () {
    test('- an album opens Play all plus its tracks', () async {
      final (env, handler) = build();
      env.stubAlbums([album('a1')]);
      when(
        () => env.setPlayback.albumSongs('a1'),
      ).thenAnswer((_) async => [song('s1'), song('s2')]);
      final home = await handler.getChildren(AutoMediaId.home);
      expect(home.first.id, 'album/a1');
      expect(home.first.playable, isFalse);

      final children = await handler.getChildren('album/a1');

      expect(children.map((c) => c.id), [
        'album/a1/all',
        'song/s1?ctx=album%3Aa1',
        'song/s2?ctx=album%3Aa1',
      ]);
      expect(children.first.title, 'Play all');
      expect(children.first.artist, 'Album a1');
      expect(children.skip(1).every((c) => c.playable == true), isTrue);
    });

    test('- liked songs and mixes resolve to their own fetchers', () async {
      final (env, handler) = build(favouriteSongs: [song('fav')]);
      when(
        env.setPlayback.favouriteSongs,
      ).thenAnswer((_) async => [song('fav')]);

      final children = await handler.getChildren(
        'mix/jellybox%3Aliked-songs',
      );

      expect(children.map((c) => c.id), [
        'mix/jellybox%3Aliked-songs/all',
        'song/fav?ctx=mix%3Ajellybox%3Aliked-songs',
      ]);
    });

    test(
      '- Play all plays the set, a track plays the set from there',
      () async {
        final (env, handler) = build();
        env.stubAlbums([album('a1')]);
        when(
          () => env.setPlayback.albumSongs('a1'),
        ).thenAnswer((_) async => [song('s1'), song('s2')]);
        await handler.getChildren(AutoMediaId.home);
        await handler.getChildren('album/a1');

        await handler.playFromMediaId('album/a1/all');
        await handler.playFromMediaId('song/s2?ctx=album%3Aa1');

        verify(() => env.setPlayback.playAlbum(album('a1'))).called(1);
        final call = verify(
          () => env.playbackNotifier.play(
            captureAny(),
            captureAny(),
            captureAny(),
          ),
        ).captured;
        expect((call[0] as LibraryItem).id, 's2');
        expect((call[1] as List<LibraryItem>).map((s) => s.id), ['s1', 's2']);
        expect((call[2] as LibraryItem).id, 'a1');
      },
    );

    test('- an unknown set has no children', () async {
      final (_, handler) = build();

      expect(await handler.getChildren('playlist/nope'), isEmpty);
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

  group('shuffle from the car', () {
    test('- maps the session shuffle mode onto app-level shuffle', () async {
      final (env, handler) = build();

      await handler.setShuffleMode(AudioServiceShuffleMode.all);
      await handler.setShuffleMode(AudioServiceShuffleMode.none);

      verifyInOrder([
        () => env.playbackNotifier.setShuffle(enabled: true),
        () => env.playbackNotifier.setShuffle(enabled: false),
      ]);
    });
  });

  group('custom controls', () {
    test('- reflect shuffle and repeat state in the icons', () {
      final (env, handler) = build();
      when(() => env.player.loopMode).thenReturn(LoopMode.all);

      final controls = handler.customControls();

      expect(controls.map((c) => c.androidIcon), [
        'drawable/ic_auto_shuffle',
        'drawable/ic_auto_repeat_on',
      ]);
      expect(controls.map((c) => c.customAction?.name), [
        AndroidAutoHandler.shuffleAction,
        AndroidAutoHandler.repeatAction,
      ]);
    });

    test('- show shuffle on when the queue is shuffled', () {
      final (_, handler) = build(
        playback: playbackState([song('s1')], 0).copyWith(shuffleEnabled: true),
      );

      expect(
        handler.customControls().first.androidIcon,
        'drawable/ic_auto_shuffle_on',
      );
    });

    test('- toggle shuffle and repeat when tapped', () async {
      final (env, handler) = build();

      await handler.customAction(AndroidAutoHandler.shuffleAction, null);
      await handler.customAction(AndroidAutoHandler.repeatAction, null);
      when(() => env.player.loopMode).thenReturn(LoopMode.all);
      await handler.customAction(AndroidAutoHandler.repeatAction, null);
      await handler.customAction('unknown', null);

      verify(() => env.playbackNotifier.setShuffle(enabled: true)).called(1);
      verifyInOrder([
        () => env.player.setLoopMode(LoopMode.all),
        () => env.player.setLoopMode(LoopMode.off),
      ]);
    });
  });

  group('favourite control', () {
    test('- is absent without a current track', () {
      final (_, handler) = build();

      expect(handler.customControls(), hasLength(2));
    });

    test('- shows the heart state of the current track', () {
      final liked = song('s1').copyWith(
        userData: const PlaybackUserData(isFavorite: true),
      );
      final (_, handler) = build(playback: playbackState([liked], 0));

      final control = handler.customControls().last;

      expect(control.androidIcon, 'drawable/ic_auto_favourite');
      expect(control.customAction?.name, AndroidAutoHandler.favouriteAction);
    });

    test('- toggles on the server and updates the queue', () async {
      final (env, handler) = build(playback: playbackState([song('s1')], 0));

      await handler.customAction(AndroidAutoHandler.favouriteAction, null);

      verify(() => env.client.setFavorite('s1', favorite: true)).called(1);
      final updated =
          verify(
                () => env.playbackNotifier.updateSong(captureAny()),
              ).captured.single
              as LibraryItem;
      expect(updated.userData.isFavorite, isTrue);
    });

    test('- does nothing offline', () async {
      final (env, handler) = build(
        offline: true,
        playback: playbackState([song('s1')], 0),
      );

      await handler.customAction(AndroidAutoHandler.favouriteAction, null);

      verifyNever(
        () => env.client.setFavorite(any(), favorite: any(named: 'favorite')),
      );
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
