import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart' hide LibraryPage;
import 'package:jplayer/src/presentation/pages/pages.dart';

class ScreenFactory {
  const ScreenFactory();

  Page<void> albumPage(
    BuildContext context,
    GoRouterState router,
  ) {
    final params = router.extra! as Map<String, dynamic>;
    final album = params['album'] is LibraryItem
        ? params['album'] as LibraryItem
        : LibraryItem.fromJson(params['album'] as Map<String, dynamic>);

    return CupertinoPage(
      child: AlbumPage(album: album),
    );
  }

  Page<void> artistPage(
    BuildContext context,
    GoRouterState router,
  ) {
    final params = router.extra! as Map<String, dynamic>;
    final artist = params['artist'] is LibraryItem
        ? params['artist'] as LibraryItem
        : LibraryItem.fromJson(params['artist'] as Map<String, dynamic>);

    return CupertinoPage(
      child: ArtistPage(artist: artist),
    );
  }

  Page<void> genrePage(
    BuildContext context,
    GoRouterState router,
  ) {
    final params = router.extra! as Map<String, dynamic>;
    final genre = params['genre'] is LibraryItem
        ? params['genre'] as LibraryItem
        : LibraryItem.fromJson(params['genre'] as Map<String, dynamic>);

    return CupertinoPage(
      child: GenreAlbumsPage(genre: genre),
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

  Page<void> browsePage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const NoTransitionPage(
      child: BrowsePage(),
    );
  }

  Page<void> favouritesPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const CupertinoPage(
      child: FavouritesPage(),
    );
  }

  Page<void> favouriteSongsPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const CupertinoPage(
      child: FavouriteSongsPage(),
    );
  }

  Page<void> homePage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const NoTransitionPage(
      child: HomePage(),
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
    final playlist = params['playlist'] is LibraryItem
        ? params['playlist'] as LibraryItem
        : LibraryItem.fromJson(params['playlist'] as Map<String, dynamic>);

    return CupertinoPage(
      child: PlaylistPage(playlist: playlist),
    );
  }

  Page<void> searchResultsPage(
    BuildContext context,
    GoRouterState router,
  ) {
    final params = router.extra! as Map<String, dynamic>;

    return CupertinoPage(
      child: SearchResultsPage(category: params['category'] as ItemList),
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
