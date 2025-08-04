import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/dto/dto.dart';
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

  static void _handleMediaKey(String event, WidgetRef ref) => switch (event) {
    'playPause' => ref.read(playbackProvider.notifier).playPause(),
    'next' => ref.read(playbackProvider.notifier).next(),
    'prev' => ref.read(playbackProvider.notifier).prev(),
    _ => debugPrint('Unknown event: $event'),
  };
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
  late final GoRouter _router;
  final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final _authState = ValueNotifier<bool?>(null);
  ItemDTO? _selectedLibrary;

  @override
  void initState() {
    super.initState();
    MediaKeyHandler.initialize(ref);
    initRoutes();
  }

  void initRoutes() {
    _router = GoRouter(
      initialLocation: '/',
      navigatorKey: _rootNavigatorKey,
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: widget.screenFactory.initialPage,
        ),
        GoRoute(
          path: Routes.login.path,
          name: Routes.login.name,
          pageBuilder: widget.screenFactory.loginPage,
        ),
        GoRoute(
          path: Routes.library.path,
          name: Routes.library.name,
          pageBuilder: widget.screenFactory.libraryPage,
        ),
        StatefulShellRoute.indexedStack(
          pageBuilder: widget.screenFactory.mainPage,
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.listen.path,
                  name: Routes.listen.name,
                  pageBuilder: widget.screenFactory.listenPage,
                  routes: [
                    GoRoute(
                      path: Routes.album.path,
                      name: Routes.album.name,
                      pageBuilder: widget.screenFactory.albumPage,
                    ),
                    GoRoute(
                      path: Routes.artist.path,
                      name: Routes.artist.name,
                      pageBuilder: widget.screenFactory.artistPage,
                    ),
                    GoRoute(
                      path: Routes.playlist.path,
                      name: Routes.playlist.name,
                      pageBuilder: widget.screenFactory.playlistPage,
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.search.path,
                  name: Routes.search.name,
                  pageBuilder: widget.screenFactory.searchPage,
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.settings.path,
                  name: Routes.settings.name,
                  pageBuilder: widget.screenFactory.settingsPage,
                  routes: [
                    GoRoute(
                      path: Routes.palette.path,
                      name: Routes.palette.name,
                      pageBuilder: widget.screenFactory.palettePage,
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.downloads.path,
                  name: Routes.downloads.name,
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
        final loginRoute = Routes.login.path;
        if (authenticated == null) return '/'; // If auth state is unknown
        if (!authenticated && location != loginRoute) return loginRoute;
        if (authenticated && (location == loginRoute || location == '/')) {
          final initialRoute = widget.initialRoute ?? '/';
          if (initialRoute != '/' && initialRoute != loginRoute) {
            return initialRoute;
          } else if (_selectedLibrary != null) {
            return Routes.listen.path;
          } else {
            return Routes.library.path;
          }
        }

        return null;
      },
      refreshListenable: _authState,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(authProvider, (previous, next) {
        if (next.hasError) {
          _authState.value = false;
        } else {
          _authState.value = next.value;
        }
      })
      ..listen(currentLibraryProvider, (previous, next) {
        _selectedLibrary = next.valueOrNull;
      });

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
