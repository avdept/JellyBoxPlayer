import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/android_auto/android_auto_handler.dart';
import 'package:jplayer/src/core/android_auto/auto_media_id.dart';
import 'package:jplayer/src/core/car/car_content.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:mocktail/mocktail.dart';

import '../car/car_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  (CarTestEnv, AndroidAutoHandler) build({
    bool signedIn = true,
    bool offline = false,
    List<GeneratedPlaylist> mixes = const [],
    List<DownloadedAlbum> downloads = const [],
    PlaybackState? playback,
  }) {
    final env = CarTestEnv(
      signedIn: signedIn,
      offline: offline,
      mixes: mixes,
      downloads: downloads,
      playback: playback,
    );
    return (env, AndroidAutoHandler(env.container, CarContent(env.container)));
  }

  Future<List<String>> ids(AndroidAutoHandler handler, String parent) async =>
      (await handler.getChildren(parent)).map((c) => c.id).toList();

  group('root', () {
    test('- asks to sign in when there is no user', () async {
      final (_, handler) = build(signedIn: false);

      expect(await ids(handler, AutoMediaId.root), [AutoMediaId.signIn]);
    });

    test(
      '- keeps the tabs offline and refills Home when back online',
      () async {
        final (env, handler) = build(offline: true);
        env
          ..stubAlbums([album('a1')])
          ..stubPlaylists(const []);

        expect(await ids(handler, AutoMediaId.root), [
          AutoMediaId.home,
          AutoMediaId.library,
          AutoMediaId.downloads,
        ]);
        expect(await ids(handler, AutoMediaId.home), [AutoMediaId.offline]);
        expect(await ids(handler, AutoMediaId.library), [AutoMediaId.offline]);

        final refreshed = expectLater(handler.childrenChanged, emits(isNull));
        env.setOffline(false);
        await refreshed;

        expect(await ids(handler, AutoMediaId.home), ['album/a1']);
        expect(await handler.getChildren(AutoMediaId.library), hasLength(4));
      },
    );
  });

  group('home', () {
    test('- shows recently added, mixes and playlists as folders', () async {
      const mix = GeneratedPlaylist(
        item: LibraryItem(
          id: 'mix-1',
          name: 'Rock mix',
          kind: ItemKind.playlist,
        ),
        coverSongs: [],
      );
      final (env, handler) = build(mixes: [mix]);
      env
        ..stubAlbums(albums(12))
        ..stubPlaylists([playlist('p1')]);

      final children = await handler.getChildren(AutoMediaId.home);

      expect(children.map((c) => c.id), [
        for (var i = 0; i < AndroidAutoHandler.homeRowLimit; i++)
          'album/album-$i',
        'mix/mix-1',
        'playlist/p1',
      ]);
      expect(children.every((c) => c.playable != true), isTrue);
    });
  });

  group('library', () {
    test('- pages long lists with a Load more folder', () async {
      final (env, handler) = build();

      env.stubAlbums(albums(CarContent.pageSize));
      final full = await handler.getChildren(AutoMediaId.albums);
      env.stubAlbums(albums(3));
      final tail = await handler.getChildren('albums?start=100');

      expect(full.last.id, 'albums?start=100');
      expect(full.last.title, 'Load more…');
      expect(tail, hasLength(3));
    });

    test('- an artist opens Play all plus their albums', () async {
      final (env, handler) = build();
      env
        ..stubArtists([artist('ar1')])
        ..stubAlbums([album('a1'), album('a2')]);

      expect(await ids(handler, AutoMediaId.artists), ['artist/ar1']);
      expect(await ids(handler, 'artist/ar1'), [
        'artist/ar1/all',
        'album/a1',
        'album/a2',
      ]);
    });

    test('- an album opens Play all plus its tracks, both playable', () async {
      final (env, handler) = build();
      env.stubAlbums([album('a1')]);
      when(
        () => env.setPlayback.albumSongs('a1'),
      ).thenAnswer((_) async => [song('s1'), song('s2')]);
      await handler.getChildren(AutoMediaId.home);

      expect(await ids(handler, 'album/a1'), [
        'album/a1/all',
        'song/s1?ctx=album%3Aa1',
        'song/s2?ctx=album%3Aa1',
      ]);

      await handler.playFromMediaId('album/a1/all');
      await handler.playFromMediaId('song/s2?ctx=album%3Aa1');

      verify(() => env.setPlayback.playAlbum(album('a1'))).called(1);
      final call = verify(
        () =>
            env.playbackNotifier.play(captureAny(), captureAny(), captureAny()),
      ).captured;
      expect((call[0] as LibraryItem).id, 's2');
      expect((call[1] as List<LibraryItem>).map((s) => s.id), ['s1', 's2']);
      expect((call[2] as LibraryItem).id, 'a1');
    });

    test('- downloads open their tracks', () async {
      final (env, handler) = build(
        offline: true,
        downloads: [
          DownloadedAlbum(
            item: album('d1'),
            sizeInBytes: 1,
            downloadDate: DateTime(2026),
          ),
        ],
      );
      when(
        () => env.setPlayback.albumSongs('d1'),
      ).thenAnswer((_) async => [song('s1')]);

      expect(await ids(handler, AutoMediaId.downloads), ['download/d1']);
      expect(await ids(handler, 'download/d1'), [
        'download/d1/all',
        'song/s1?ctx=download%3Ad1',
      ]);
    });
  });

  group('search', () {
    test('- labels results by type and plays songs from the results', () async {
      final (env, handler) = build();
      env.stubSearch(
        artists: [artist('ar1')],
        albums: [album('a1')],
        songs: [song('s1'), song('s2')],
      );

      final results = await handler.search('foo');

      expect(results.map((c) => c.id), [
        'artist/ar1',
        'album/a1',
        'song/s1?ctx=search',
        'song/s2?ctx=search',
      ]);
      expect(results.map((c) => c.artist), [
        'Artist',
        'Album',
        'Song • Artist',
        'Song • Artist',
      ]);

      await handler.playFromMediaId(results.last.id);

      final call = verify(
        () =>
            env.playbackNotifier.play(captureAny(), captureAny(), captureAny()),
      ).captured;
      expect((call[0] as LibraryItem).id, 's2');
      expect((call[1] as List<LibraryItem>).map((s) => s.id), ['s1', 's2']);
    });
  });

  group('voice', () {
    test(
      '- honours the focus hint, else exact title, else first song',
      () async {
        final (env, handler) = build();
        env.stubSearch(
          artists: [artist('ar1')],
          albums: [album('a1')],
          songs: [song('s1')],
        );

        await handler.playFromSearch('anything', {
          'android.intent.extra.focus': 'vnd.android.cursor.item/album',
        });
        await handler.playFromSearch('artist AR1');
        await handler.playFromSearch('something else');

        verify(() => env.setPlayback.playAlbum(album('a1'))).called(1);
        verify(() => env.setPlayback.playArtist(artist('ar1'))).called(1);
        final call = verify(
          () => env.playbackNotifier.play(
            captureAny(),
            captureAny(),
            captureAny(),
          ),
        ).captured;
        expect((call[0] as LibraryItem).id, 's1');
      },
    );

    test('- an empty query resumes the current queue', () async {
      final (env, handler) = build(playback: playbackState([song('s1')], 0));

      await handler.playFromSearch('');

      verify(() => env.playbackNotifier.resume()).called(1);
      verifyNever(() => env.client.searchSongs(any()));
    });
  });

  group('now playing', () {
    test('- exposes the current track for playback resumption', () async {
      final (env, handler) = build(
        playback: playbackState([song('s1'), song('s2')], 1),
      );

      final recent = await handler.getChildren(AutoMediaId.recent);
      await handler.playFromMediaId(AutoMediaId.resume);

      expect(recent.single.title, 'Song s2');
      verify(() => env.playbackNotifier.resume()).called(1);
    });

    test('- shuffle and repeat buttons toggle the app state', () async {
      final (env, handler) = build();

      await handler.customAction(AndroidAutoHandler.shuffleAction, null);
      await handler.customAction(AndroidAutoHandler.repeatAction, null);
      when(() => env.player.loopMode).thenReturn(LoopMode.all);
      await handler.customAction(AndroidAutoHandler.repeatAction, null);

      verify(() => env.playbackNotifier.setShuffle(enabled: true)).called(1);
      verifyInOrder([
        () => env.player.setLoopMode(LoopMode.all),
        () => env.player.setLoopMode(LoopMode.off),
      ]);
    });

    test(
      '- the like button updates the server and the queue, not offline',
      () async {
        final (env, handler) = build(playback: playbackState([song('s1')], 0));

        await handler.customAction(AndroidAutoHandler.favouriteAction, null);
        env.setOffline(true);
        await handler.customAction(AndroidAutoHandler.favouriteAction, null);

        verify(() => env.client.setFavorite('s1', favorite: true)).called(1);
        final updated =
            verify(
                  () => env.playbackNotifier.updateSong(captureAny()),
                ).captured.single
                as LibraryItem;
        expect(updated.userData.isFavorite, isTrue);
      },
    );
  });

  test('- downloaded covers are served through the content provider', () {
    final rewritten = AndroidAutoHandler.autoArtUri(
      Uri.file('/data/user/0/app/app_flutter/music/ab12/cover.jpg'),
    );
    final server = Uri.parse('https://jf.example/Items/1/Images/Primary');

    expect(
      rewritten.toString(),
      'content://${AndroidAutoHandler.coverAuthority}/ab12',
    );
    expect(AndroidAutoHandler.autoArtUri(server), same(server));
  });
}
