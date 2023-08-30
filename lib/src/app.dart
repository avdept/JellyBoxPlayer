import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/screen_factory.dart';

class App extends StatefulWidget {
  const App({
    required this.screenFactory,
    this.initialRoute,
    super.key,
  });

  final ScreenFactory screenFactory;
  final String? initialRoute;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final _messengerKey = GlobalKey<ScaffoldMessengerState>(debugLabel: 'msg');
  final _authState = ValueNotifier<bool?>(true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: Themes.red,
      localizationsDelegates: const [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        S.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: GoRouter(
        initialLocation: Routes.root,
        navigatorKey: _rootNavigatorKey,
        routes: [
          GoRoute(
            path: Routes.root,
            pageBuilder: widget.screenFactory.initialPage,
          ),
          GoRoute(
            path: Routes.login,
            pageBuilder: widget.screenFactory.loginPage,
          ),
          GoRoute(
            path: Routes.library,
            pageBuilder: widget.screenFactory.libraryPage,
          ),
          StatefulShellRoute.indexedStack(
            pageBuilder: widget.screenFactory.mainPage,
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: Routes.listen,
                    pageBuilder: widget.screenFactory.listenPage,
                    routes: [
                      GoRoute(
                        path: Routes.album.name,
                        pageBuilder: widget.screenFactory.albumPage,
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: Routes.search,
                    pageBuilder: widget.screenFactory.searchPage,
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: Routes.settings,
                    pageBuilder: widget.screenFactory.settingsPage,
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: Routes.downloads,
                    pageBuilder: widget.screenFactory.downloadsPage,
                    routes: [
                      GoRoute(
                        path: Routes.album.name,
                        pageBuilder: widget.screenFactory.albumPage,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
        redirect: (context, router) async {
          final authenticated = _authState.value;
          final location = router.matchedLocation;

          if (authenticated == null) {
            return Routes.root;
          } else if (authenticated) {
            if (location.startsWith(Routes.listen)) return null;
            if (location.startsWith(Routes.search)) return null;
            if (location.startsWith(Routes.settings)) return null;
            if (location.startsWith(Routes.downloads)) return null;
            return widget.initialRoute ?? Routes.library;
          } else if (location != Routes.login) {
            return Routes.login;
          }

          return null;
        },
        refreshListenable: _authState,
      ),
      builder: (context, child) {
        final theme = Theme.of(context);

        switch (theme.brightness) {
          case Brightness.dark:
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

          case Brightness.light:
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
        }

        return child!;
      },
    );
  }

  @override
  void dispose() {
    _authState.dispose();
    super.dispose();
  }
}
