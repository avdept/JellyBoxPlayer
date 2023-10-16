import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/presentation/pages/pages.dart';

class ScreenFactory {
  const ScreenFactory();

  Page<void> albumPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return const CupertinoPage(
      child: AlbumPage(),
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
    return NoTransitionPage(
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
