import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/screen_factory.dart';

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
  final _messengerKey = GlobalKey<ScaffoldMessengerState>(debugLabel: 'msg');
  final _authState = ValueNotifier<bool?>(true);

  @override
  Widget build(BuildContext context) {
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
          final matchedLocation = router.matchedLocation;

          if (authenticated == null) {
            return Routes.root;
          } else if (authenticated) {
            if (matchedLocation.startsWith(Routes.listen)) return null;
            if (matchedLocation.startsWith(Routes.search)) return null;
            if (matchedLocation.startsWith(Routes.settings)) return null;
            if (matchedLocation.startsWith(Routes.downloads)) return null;
            return Routes.library;
          } else if (matchedLocation != Routes.login) {
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
        cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
          primaryColor: Colors.white,
          primaryContrastingColor: Color(0xFFFD2F2F),
          barBackgroundColor: Color(0xFF471F27),
          scaffoldBackgroundColor: Colors.black,
        ),
        sliderTheme: const SliderThemeData(
          trackHeight: 4,
          overlayColor: Colors.transparent,
          thumbColor: Colors.white,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 16),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF471F27),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF471F27),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF471F27),
        ),
        chipTheme: ChipThemeData(
          labelPadding: const EdgeInsets.symmetric(horizontal: 11),
          backgroundColor: const Color(0xFF362A30),
          selectedColor: const Color(0xFF0066FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
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
