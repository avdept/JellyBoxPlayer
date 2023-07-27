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
  final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
  final _messengerKey = GlobalKey<ScaffoldMessengerState>(debugLabel: 'msg');
  final _authState = ValueNotifier<bool?>(null);

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
        initialLocation: Routes.login,
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
          ShellRoute(
            navigatorKey: _shellNavigatorKey,
            pageBuilder: widget.screenFactory.mainPage,
            routes: [
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
        refreshListenable: _authState,
      ),
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        fontFamily: FontFamily.gilroy,
        scaffoldBackgroundColor: Colors.black,
      ),
    );
  }

  @override
  void dispose() {
    _authState.dispose();
    super.dispose();
  }
}
