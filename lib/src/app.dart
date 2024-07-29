import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/screen_factory.dart';

class MediaKeyHandler {
  static const MethodChannel _channel = MethodChannel('mediakeys_proxy');

  static void initialize(WidgetRef ref) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'mediaKeyPressed') {
        _handleMediaKey(call.arguments as String, ref);
      }
    });
  }

  static void _handleMediaKey(String event, WidgetRef ref) {
    switch (event) {
      case 'playPause':
        ref.read(playbackProvider.notifier).playPause();
      case 'next':
        ref.read(playbackProvider.notifier).next();
      case 'prev':
        ref.read(playbackProvider.notifier).prev();
      default:
        print('Unknown event: $event');
    }
  }
}

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
  late GoRouter _router;

  ScaffoldMessengerState get _messenger => _messengerKey.currentState!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(authProvider.notifier).checkAuthState(),
    );
    MediaKeyHandler.initialize(ref);
    initRoutes();
  }

  void initRoutes() {
    _router = GoRouter(
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
                    GoRoute(
                      path: Routes.artist.name,
                      pageBuilder: widget.screenFactory.artistPage,
                      routes: [
                        GoRoute(
                          path: Routes.album.name,
                          pageBuilder: widget.screenFactory.albumPage,
                        ),
                      ],
                    ),
                    GoRoute(
                      path: Routes.playlist.name,
                      pageBuilder: widget.screenFactory.playlistPage,
                      routes: [
                        GoRoute(
                          path: Routes.album.name,
                          pageBuilder: widget.screenFactory.albumPage,
                        ),
                        GoRoute(
                          path: Routes.artist.name,
                          pageBuilder: widget.screenFactory.artistPage,
                        ),
                      ],
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
                  routes: [
                    GoRoute(
                      path: Routes.album.name,
                      pageBuilder: widget.screenFactory.albumPage,
                    ),
                    GoRoute(
                      path: Routes.artist.name,
                      pageBuilder: widget.screenFactory.artistPage,
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
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.settings,
                  pageBuilder: widget.screenFactory.settingsPage,
                  routes: [
                    GoRoute(
                      path: Routes.palette.name,
                      pageBuilder: widget.screenFactory.palettePage,
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.downloads,
                  pageBuilder: widget.screenFactory.downloadsPage,
                ),
              ],
            ),
          ],
        ),
      ],
      redirect: (context, router) async {
        final authenticated = _authState.value;
        final location = router.matchedLocation;
        if (authenticated == null) return '/'; // If auth state is unknown
        if (!authenticated && location != Routes.login) return Routes.login;
        if (authenticated && (location == Routes.login || location == '/')) {
          final selectedLibrary = ref.read(currentLibraryProvider);
          final initialRoute = widget.initialRoute ?? '/';

          return (initialRoute == '/' || initialRoute == Routes.login)
              ? ((selectedLibrary != null) ? Routes.listen : Routes.library)
              : initialRoute;
        }

        return null;
      },
      refreshListenable: _authState,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      authProvider,
      (previous, next) {
        if (next.error != null) {
          _authState.value = false;
        } else {
          _authState.value = next.value;
        }
      },
    );

    return MaterialApp.router(
      theme: Themes.red,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        S.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: _router,
      builder: (context, child) {
        final theme = Theme.of(context);

        SystemChrome.setSystemUIOverlayStyle(
          switch (theme.brightness) {
            Brightness.dark => SystemUiOverlayStyle.light,
            Brightness.light => SystemUiOverlayStyle.dark,
          },
        );

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
