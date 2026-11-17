import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/on_repeat_provider.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_album_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_artist_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_browse_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_genre_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_home_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_launch_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_library_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_main_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_now_playing_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_playlist_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_settings_page.dart';
import 'package:jplayer/src/screen_factory.dart';

class TvScreenFactory extends ScreenFactory {
  const TvScreenFactory();

  @override
  Page<void> initialPage(BuildContext context, GoRouterState router) =>
      const NoTransitionPage(child: TvLaunchPage());

  @override
  Page<void> libraryPage(BuildContext context, GoRouterState router) =>
      const NoTransitionPage(child: TvLibraryPage());

  @override
  Page<void> mainPage(
    BuildContext context,
    GoRouterState router,
    StatefulNavigationShell shell,
  ) => NoTransitionPage(child: TvMainPage(shell: shell));

  @override
  Page<void> homePage(BuildContext context, GoRouterState router) =>
      const NoTransitionPage(child: TvHomePage());

  @override
  Page<void> settingsPage(BuildContext context, GoRouterState router) =>
      const NoTransitionPage(child: TvSettingsPage());

  @override
  Page<void> nowPlayingPage(BuildContext context, GoRouterState router) =>
      const NoTransitionPage(child: TvNowPlayingPage());

  @override
  Page<void> browsePage(BuildContext context, GoRouterState router) =>
      const NoTransitionPage(child: TvBrowsePage());

  @override
  Page<void> albumPage(BuildContext context, GoRouterState router) =>
      CupertinoPage(child: TvAlbumPage(album: itemParam(router, 'album')));

  @override
  Page<void> artistPage(BuildContext context, GoRouterState router) =>
      CupertinoPage(child: TvArtistPage(artist: itemParam(router, 'artist')));

  @override
  Page<void> genrePage(BuildContext context, GoRouterState router) =>
      CupertinoPage(child: TvGenrePage(genre: itemParam(router, 'genre')));

  @override
  Page<void> playlistPage(BuildContext context, GoRouterState router) =>
      CupertinoPage(
        child: TvPlaylistPage(
          playlist: itemParam(router, 'playlist'),
          source: TvPlaylistSource.playlist,
        ),
      );

  @override
  Page<void> favouriteSongsPage(BuildContext context, GoRouterState router) =>
      CupertinoPage(
        child: Consumer(
          builder: (context, ref, _) {
            final liked = ref.watch(likedSongsPlaylistProvider);
            if (liked == null) return const SizedBox.shrink();
            return TvPlaylistPage(
              playlist: liked,
              source: TvPlaylistSource.likedSongs,
            );
          },
        ),
      );

  @override
  Page<void> onRepeatPage(BuildContext context, GoRouterState router) =>
      CupertinoPage(
        child: Consumer(
          builder: (context, ref, _) {
            final onRepeat = ref.watch(onRepeatPlaylistProvider);
            if (onRepeat == null) return const SizedBox.shrink();
            return TvPlaylistPage(
              playlist: onRepeat,
              source: TvPlaylistSource.onRepeat,
            );
          },
        ),
      );

  @override
  Page<void> generatedPlaylistPage(
    BuildContext context,
    GoRouterState router,
  ) => CupertinoPage(
    child: TvPlaylistPage(
      playlist: itemParam(router, 'playlist'),
      source: TvPlaylistSource.generated,
    ),
  );
}
