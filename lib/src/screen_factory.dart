import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/presentation/pages/pages.dart';

class ScreenFactory {
  const ScreenFactory();

  Page<void> albumPage(
    BuildContext context,
    GoRouterState router,
  ) {
    final params = router.extra! as Map<String, dynamic>;
    final album = params['album'] is ItemDTO
        ? params['album'] as ItemDTO
        : ItemDTO.fromJson(params['album'] as Map<String, dynamic>);

    return CupertinoPage(
      child: AlbumPage(album: album),
    );
  }

  Page<void> artistPage(
    BuildContext context,
    GoRouterState router,
  ) {
    final params = router.extra! as Map<String, dynamic>;
    final artist = params['artist'] is ItemDTO
        ? params['artist'] as ItemDTO
        : ItemDTO.fromJson(params['artist'] as Map<String, dynamic>);

    return CupertinoPage(
      child: ArtistPage(artist: artist),
    );
  }

  Page<void> downloadsPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const NoTransitionPage(
      child: DownloadsPage(),
    );
  }

  Page<void> favoritesPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const NoTransitionPage(
      child: ListenPage.favorites(),
    );
  }

  Page<void> initialPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const CupertinoPage(
      child: InitialPage(),
    );
  }

  Page<void> libraryPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const NoTransitionPage(
      child: LibraryPage(),
    );
  }

  Page<void> listenPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const NoTransitionPage(
      child: ListenPage(),
    );
  }

  Page<void> loginPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const CupertinoPage(
      child: LoginPage(),
    );
  }

  Page<void> mainPage(
    BuildContext context,
    GoRouterState router,
    StatefulNavigationShell shell,
  ) {
    return CupertinoPage(
      child: MainPage(shell: shell),
    );
  }

  Page<void> palettePage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const NoTransitionPage(
      child: ColorPalettePage(),
    );
  }

  Page<void> playlistPage(
    BuildContext context,
    GoRouterState router,
  ) {
    final params = router.extra! as Map<String, dynamic>;
    final playlist = params['playlist'] is ItemDTO
        ? params['playlist'] as ItemDTO
        : ItemDTO.fromJson(params['playlist'] as Map<String, dynamic>);

    return CupertinoPage(
      child: PlaylistPage(playlist: playlist),
    );
  }

  Page<void> searchPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const NoTransitionPage(
      child: SearchPage(),
    );
  }

  Page<void> settingsPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const NoTransitionPage(
      child: SettingsPage(),
    );
  }
}
