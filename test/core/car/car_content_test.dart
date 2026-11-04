import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/car/car_content.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/providers/shared_preferences_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/on_repeat_provider.dart';
import 'package:jplayer/src/domain/providers/user_playlists_provider.dart';
import 'package:mocktail/mocktail.dart';

import 'car_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CarContent.list', () {
    test('- pages by 100 and follows the car sort', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);
      content.setSort('sortName');

      env.stubAlbums(albums(CarContent.pageSize));
      final first = await content.list(type: 'albums');
      env.stubAlbums(albums(5));
      final second = await content.list(type: 'albums', startIndex: 100);

      expect(first.hasMore, isTrue);
      expect(second.hasMore, isFalse);
      final queries = verify(
        () => env.client.getAlbums(captureAny()),
      ).captured.cast<LibraryQuery>();
      expect(queries.map((q) => q.startIndex), [0, 100]);
      expect(queries.first.sort, ItemSort.name);
    });

    test('- puts the user playlists that have songs first', () async {
      final env = CarTestEnv(favouriteSongs: [song('s1')], onRepeat: true);
      final content = CarContent(env.container);
      env.stubPlaylists([playlist('p1')]);
      await env.container.read(availableUserPlaylistsProvider.future);

      final page = await content.list(type: 'playlists');

      expect(page.entries.map((e) => e.id), [
        likedSongsPlaylistFor('user-1').id,
        onRepeatPlaylistFor('user-1').id,
        'p1',
      ]);
      expect(page.entries[1].title, UserPlaylist.onRepeat.name);
    });

    test('- hides a user playlist that has nothing in it', () async {
      final env = CarTestEnv(favouriteSongs: [song('s1')]);
      final content = CarContent(env.container);
      env.stubPlaylists([playlist('p1')]);
      await env.container.read(availableUserPlaylistsProvider.future);

      final page = await content.list(type: 'playlists');

      expect(page.entries.map((e) => e.id), [
        likedSongsPlaylistFor('user-1').id,
        'p1',
      ]);
    });

    test('- plays On repeat as a playlist', () async {
      final env = CarTestEnv(onRepeat: true);
      final content = CarContent(env.container);
      final onRepeat = onRepeatPlaylistFor('user-1');

      await content.play('playlist', onRepeat.id);

      verify(() => env.setPlayback.playPlaylist(onRepeat)).called(1);
    });

    test('- adds appears-on albums to an artist page once', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);
      when(() => env.client.getAlbums(any())).thenAnswer((invocation) async {
        final query = invocation.positionalArguments.single as LibraryQuery;
        return LibraryPage(
          items: query.appearsOnArtistId != null
              ? [album('own'), album('guest')]
              : [album('own')],
        );
      });

      final first = await content.list(type: 'albums', artistId: 'ar1');
      final next = await content.list(
        type: 'albums',
        artistId: 'ar1',
        startIndex: 100,
      );

      expect(first.entries.map((e) => e.id), ['own', 'guest']);
      expect(next.entries.map((e) => e.id), ['own']);
    });
  });

  group('CarContent.play', () {
    test('- routes sets to playback and fetches ids it has not seen', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);
      env.stubPlaylists([playlist('p1')]);
      await content.list(type: 'playlists');
      when(
        () => env.client.getItem('a9', kind: ItemKind.album),
      ).thenAnswer((_) async => album('a9'));

      await content.play('playlist', 'p1');
      await content.play('album', 'a9');
      await content.play('mix', likedSongsPlaylistFor('user-1').id);

      verify(() => env.setPlayback.playPlaylist(playlist('p1'))).called(1);
      verify(() => env.setPlayback.playAlbum(album('a9'))).called(1);
      verify(
        () =>
            env.setPlayback.playFavouriteSongs(likedSongsPlaylistFor('user-1')),
      ).called(1);
    });

    test('- keeps a play from the car on this device', () async {
      final env = CarTestEnv(playingElsewhere: true);
      final content = CarContent(env.container);
      when(
        () => env.client.getItem('a9', kind: ItemKind.album),
      ).thenAnswer((_) async => album('a9'));

      await content.play('album', 'a9');

      verify(() => env.playbackNotifier.playingHere(any())).called(1);
      verify(() => env.setPlayback.playAlbum(album('a9'))).called(1);
    });

    test('- plays a song with the list it was shown in as the queue', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);
      env.stubSearch(songs: [song('s1'), song('s2')]);
      await content.search('foo');

      await content.play('song', 's2', songContext: CarContent.searchContext);

      final call = verify(
        () => env.playbackNotifier.play(
          captureAny(),
          captureAny(),
          captureAny(),
          sourceId: captureAny(named: 'sourceId'),
        ),
      ).captured;
      expect((call[0] as LibraryItem).id, 's2');
      expect((call[1] as List<LibraryItem>).map((s) => s.id), ['s1', 's2']);
    });
  });

  group('CarContent.carConnected', () {
    test('- brings the session here when the setting is on', () async {
      final env = CarTestEnv(playingElsewhere: true);
      final content = CarContent(env.container);
      await env.container.read(sharedPreferencesProvider.future);
      env.container
          .read(appSettingsProvider.notifier)
          .setEnabled(AppSetting.carTakesQueue, value: true);
      when(env.outputController.playHere).thenAnswer((_) async {});

      await content.carConnected();

      verify(env.outputController.playHere).called(1);
    });

    test('- leaves the other device alone by default', () async {
      final env = CarTestEnv(playingElsewhere: true);
      final content = CarContent(env.container);

      await content.carConnected();

      verifyNever(env.outputController.playHere);
    });

    test('- does nothing when nothing plays elsewhere', () async {
      final env = CarTestEnv();
      final content = CarContent(env.container);
      await env.container.read(sharedPreferencesProvider.future);
      env.container
          .read(appSettingsProvider.notifier)
          .setEnabled(AppSetting.carTakesQueue, value: true);

      await content.carConnected();

      verifyNever(env.outputController.playHere);
    });
  });

  test('- announces a change when connectivity comes back', () async {
    final env = CarTestEnv(offline: true);
    final content = CarContent(env.container);

    final changed = expectLater(content.contentChanged, emits(anything));
    env.setOffline(false);

    await changed;
  });
}
