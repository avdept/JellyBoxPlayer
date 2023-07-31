import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/presentation/pages/pages.dart';

class ScreenFactory {
  const ScreenFactory();

  Page<void> downloadsPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return NoTransitionPage(
      key: router.pageKey,
      name: router.path,
      child: const DownloadsPage(),
    );
  }

  Page<void> initialPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return MaterialPage(
      key: router.pageKey,
      name: router.path,
      child: const InitialPage(),
    );
  }

  Page<void> libraryPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return NoTransitionPage(
      key: router.pageKey,
      name: router.path,
      child: const LibraryPage(),
    );
  }

  Page<void> listenPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return NoTransitionPage(
      key: router.pageKey,
      name: router.path,
      child: const ListenPage(),
    );
  }

  Page<void> loginPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return MaterialPage(
      key: router.pageKey,
      name: router.path,
      child: const LoginPage(),
    );
  }

  Page<void> mainPage(
    BuildContext context,
    GoRouterState router,
    Widget child,
  ) {
    return MaterialPage(
      key: router.pageKey,
      name: router.path,
      child: MainPage(child: child),
    );
  }

  Page<void> searchPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return NoTransitionPage(
      key: router.pageKey,
      name: router.path,
      child: const SearchPage(),
    );
  }

  Page<void> settingsPage(
    BuildContext context,
    GoRouterState router,
  ) {
    return NoTransitionPage(
      key: router.pageKey,
      name: router.path,
      child: const SettingsPage(),
    );
  }
}
