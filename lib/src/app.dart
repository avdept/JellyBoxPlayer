import 'dart:async' show Timer, scheduleMicrotask, unawaited;
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/window_size_storage.dart';
import 'package:jplayer/src/domain/providers/current_day_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/studio_mode_provider.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/widgets/playback_keyboard_shortcuts.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/screen_factory.dart';
import 'package:window_manager/window_manager.dart';

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

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  late final GoRouter _router;
  final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final _authState = ValueNotifier<bool?>(null);
  LibraryItem? _selectedLibrary;
  Timer? _resizeTimer;
  AppLifecycleListener? _lifecycleListener;
  var _playbackRestoreStarted = false;

  @override
  void initState() {
    super.initState();
    MediaKeyHandler.initialize(ref);
    final auth = ref.read(authProvider);
    _authState.value = auth.hasError ? false : auth.valueOrNull;
    _selectedLibrary = ref.read(currentLibraryProvider).valueOrNull;
    if (_selectedLibrary != null) {
      _maybeRestorePlayback();
    }
    initRoutes();
    WidgetsBinding.instance.addObserver(this);
    _watchDayRollover();
  }

  void _checkDayRollover() {
    scheduleMicrotask(() {
      if (!mounted) return;
      ref.read(currentDayProvider.notifier).check();
    });
  }

  void _watchDayRollover() {
    _checkDayRollover();
    _lifecycleListener = AppLifecycleListener(onResume: _checkDayRollover);
    _router.routerDelegate.addListener(_checkDayRollover);
  }

  void _maybeRestorePlayback() {
    if (_playbackRestoreStarted) return;
    _playbackRestoreStarted = true;
    unawaited(_restorePlaybackWhenAuthReady());
  }

  Future<void> _restorePlaybackWhenAuthReady() async {
    try {
      final authed = await ref.read(authProvider.future);
    } on Object catch (e) {
      return;
    }
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    final baseUrl = ref.read(baseUrlProvider);
    await ref.read(playbackProvider.notifier).tryRestore();
  }

  @override
  void didChangeMetrics() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      _resizeTimer?.cancel();
      _resizeTimer = Timer(
        const Duration(seconds: 2),
        () async {
          _resizeTimer = null;
          if (supportsWindowFullscreen && await windowManager.isFullScreen()) {
            return;
          }
          ref.read(sharedPreferencesProvider).whenData((prefs) {
            if (mounted) WindowSizeStorage(prefs).saveWindowSize(context.size!);
          });
        },
      );
    }
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
                  path: Routes.home.path,
                  name: Routes.home.name,
                  pageBuilder: widget.screenFactory.homePage,
                  routes: [
                    GoRoute(
                      path: Routes.homeAlbum.path,
                      name: Routes.homeAlbum.name,
                      pageBuilder: widget.screenFactory.albumPage,
                    ),
                    GoRoute(
                      path: Routes.homeArtist.path,
                      name: Routes.homeArtist.name,
                      pageBuilder: widget.screenFactory.artistPage,
                    ),
                    GoRoute(
                      path: Routes.homePlaylist.path,
                      name: Routes.homePlaylist.name,
                      pageBuilder: widget.screenFactory.playlistPage,
                    ),
                    GoRoute(
                      path: Routes.homeGenre.path,
                      name: Routes.homeGenre.name,
                      pageBuilder: widget.screenFactory.genrePage,
                    ),
                    GoRoute(
                      path: Routes.homeGeneratedPlaylist.path,
                      name: Routes.homeGeneratedPlaylist.name,
                      pageBuilder: widget.screenFactory.generatedPlaylistPage,
                    ),
                    GoRoute(
                      path: Routes.homeFavourites.path,
                      name: Routes.homeFavourites.name,
                      pageBuilder: widget.screenFactory.favouritesPage,
                      routes: [
                        GoRoute(
                          path: Routes.homeFavouriteSongs.path,
                          name: Routes.homeFavouriteSongs.name,
                          pageBuilder: widget.screenFactory.favouriteSongsPage,
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
                  path: Routes.browse.path,
                  name: Routes.browse.name,
                  pageBuilder: widget.screenFactory.browsePage,
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
                    GoRoute(
                      path: Routes.genre.path,
                      name: Routes.genre.name,
                      pageBuilder: widget.screenFactory.genrePage,
                    ),
                    GoRoute(
                      path: Routes.searchResults.path,
                      name: Routes.searchResults.name,
                      pageBuilder: widget.screenFactory.searchResultsPage,
                    ),
                  ],
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
            return Routes.home.path;
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
        if (next.valueOrNull != null) {
          _maybeRestorePlayback();
        }
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

        return PlaybackKeyboardShortcuts(child: child!);
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.routerDelegate.removeListener(_checkDayRollover);
    _lifecycleListener?.dispose();
    _resizeTimer?.cancel();
    _authState.dispose();
    super.dispose();
  }
}
