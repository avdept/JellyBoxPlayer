import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/screen_factory.dart';
import 'package:responsive_builder/responsive_builder.dart';

class App extends StatefulWidget {
  const App({
    required this.screenFactory,
    super.key,
  });

  final ScreenFactory screenFactory;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
  final _messengerKey = GlobalKey<ScaffoldMessengerState>(debugLabel: 'msg');
  final _authState = ValueNotifier<bool?>(true);

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return MaterialApp.router(
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
          if (!isDesktop)
            GoRoute(
              path: Routes.library,
              pageBuilder: widget.screenFactory.libraryPage,
            ),
          ShellRoute(
            navigatorKey: _shellNavigatorKey,
            pageBuilder: widget.screenFactory.mainPage,
            routes: [
              if (isDesktop)
                GoRoute(
                  path: Routes.library,
                  pageBuilder: widget.screenFactory.libraryPage,
                ),
              GoRoute(
                path: Routes.listen,
                pageBuilder: widget.screenFactory.listenPage,
              ),
              GoRoute(
                path: Routes.search,
                pageBuilder: widget.screenFactory.searchPage,
              ),
              GoRoute(
                path: Routes.settings,
                pageBuilder: widget.screenFactory.settingsPage,
              ),
              GoRoute(
                path: Routes.downloads,
                pageBuilder: widget.screenFactory.downloadsPage,
              ),
            ],
          ),
        ],
        redirect: (context, router) async {
          final authenticated = _authState.value;
          final location = router.uri.toString();

          if (authenticated == null) {
            return Routes.root;
          } else if (authenticated) {
            if (location.startsWith(Routes.listen)) return null;
            if (location.startsWith(Routes.search)) return null;
            if (location.startsWith(Routes.settings)) return null;
            if (location.startsWith(Routes.downloads)) return null;
            return Routes.library;
          } else if (!location.startsWith(Routes.login)) {
            return Routes.login;
          }

          return null;
        },
        refreshListenable: _authState,
      ),
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        fontFamily: FontFamily.gilroy,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFD2F2F),
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF471F27),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF471F27),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authState.dispose();
    super.dispose();
  }
}
