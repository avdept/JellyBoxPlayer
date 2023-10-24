import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/screen_factory.dart';

class App extends ConsumerStatefulWidget {
  const App({
    required this.screenFactory,
    this.initialRoute,
    super.key,
  });

  final ScreenFactory screenFactory;
  final String? initialRoute;

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final _messengerKey = GlobalKey<ScaffoldMessengerState>(debugLabel: 'msg');
  final _authState = ValueNotifier<bool?>(null);
  bool isLoaded = false;

  ScaffoldMessengerState get _messenger => _messengerKey.currentState!;
  NavigatorState get _navigator => _rootNavigatorKey.currentState!;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(authProvider.notifier).checkAuthState().then((value) {
        setState(() {
          isLoaded = true;
          print("Init state: ${ref.read(authProvider).value}");
          _authState.value = ref.read(authProvider).value;
        });
      }),
    );
    super.initState();
    initRouter();
  }

  late GoRouter router;

  void initRouter() {
    router = GoRouter(
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
                      pageBuilder: (context, state) {
                        final params = state.extra! as Map<String, dynamic>;
                        print(params);
                        final id = params['albumId']!.toString();
                        return widget.screenFactory.albumPage(context, state, id);
                      },
                      path: Routes.album.name,
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
                      pageBuilder: (context, state) {
                        return widget.screenFactory.albumPage(context, state, "1");
                      },
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
        print('redirect fired');
        if (authenticated == null) {
          return Routes.root;
        } else if (authenticated == false) {
          return Routes.login;
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // if (!isLoaded) return MaterialApp(home: Container(child: Text('Loading')));

    ref.listen(authProvider, (previous, next) {
      if (next.error != null) {
        _authState.value = false;
      } else {
        _authState.value = next.value;
      }
    });

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
      routerConfig: router,
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
