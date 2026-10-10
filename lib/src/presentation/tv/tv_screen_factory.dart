import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_album_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_home_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_library_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_main_page.dart';
import 'package:jplayer/src/presentation/tv/pages/tv_playlist_page.dart';
import 'package:jplayer/src/screen_factory.dart';

class TvScreenFactory extends ScreenFactory {
  const TvScreenFactory();

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
  Page<void> albumPage(BuildContext context, GoRouterState router) =>
      CupertinoPage(child: TvAlbumPage(album: itemParam(router, 'album')));

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
      const CupertinoPage(
        child: TvPlaylistPage(
          playlist: likedSongsPlaylist,
          source: TvPlaylistSource.likedSongs,
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
