import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/screen_factory.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
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

  PaletteGenerator? _paletteGenerator;
  ColorScheme? _colorScheme;
  late Brightness _brightness;
  late Size _screenSize;
  late bool _isDesktop;

  Future<void> _updateUIColors(ImageProvider imageProvider) async {
    final darkTheme = _brightness == Brightness.dark;
    _paletteGenerator = await PaletteGenerator.fromImageProvider(
      imageProvider,
    );
    _colorScheme = await ColorScheme.fromImageProvider(
      provider: imageProvider,
      brightness: _brightness,
      background: darkTheme ? Colors.black : Colors.white,
      onBackground: darkTheme ? Colors.white : Colors.black,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenSize = MediaQuery.sizeOf(context);

    final deviceType = getDeviceType(_screenSize);
    _isDesktop = deviceType == DeviceScreenType.desktop;

    _brightness = context.watch<Brightness>();
    final imageProvider = context.watch<ImageProvider>();
    _updateUIColors(imageProvider);
  }

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
          if (!_isDesktop)
            GoRoute(
              path: Routes.library,
              pageBuilder: widget.screenFactory.libraryPage,
            ),
          ShellRoute(
            navigatorKey: _shellNavigatorKey,
            pageBuilder: widget.screenFactory.mainPage,
            routes: [
              if (_isDesktop)
                GoRoute(
                  path: Routes.library,
                  pageBuilder: widget.screenFactory.libraryPage,
                ),
              GoRoute(
                path: Routes.listen,
                pageBuilder: widget.screenFactory.listenPage,
                routes: [
                  GoRoute(
                    path: Routes.album.name,
                    pageBuilder: widget.screenFactory.albumPage,
                    parentNavigatorKey: _rootNavigatorKey,
                  ),
                ],
              ),
              GoRoute(
                path: Routes.search,
                pageBuilder: widget.screenFactory.searchPage,
                routes: [
                  GoRoute(
                    path: Routes.album.name,
                    pageBuilder: widget.screenFactory.albumPage,
                    parentNavigatorKey: _rootNavigatorKey,
                  ),
                ],
              ),
              GoRoute(
                path: Routes.settings,
                pageBuilder: widget.screenFactory.settingsPage,
              ),
              GoRoute(
                path: Routes.downloads,
                pageBuilder: widget.screenFactory.downloadsPage,
                routes: [
                  GoRoute(
                    path: Routes.album.name,
                    pageBuilder: widget.screenFactory.albumPage,
                    parentNavigatorKey: _rootNavigatorKey,
                  ),
                ],
              ),
              GoRoute(
                path: Routes.palette,
                pageBuilder: widget.screenFactory.palettePage,
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
            if (matchedLocation.startsWith(Routes.palette)) return null;
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
        fontFamily: FontFamily.gilroy,
        colorScheme: _colorScheme,
        cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
          barBackgroundColor: _paletteGenerator?.darkVibrantColor?.color,
        ),
        scaffoldBackgroundColor: Colors.black,
        cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
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
          showDragHandle: true,
          dragHandleSize: const Size(113, 10),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: _paletteGenerator?.darkVibrantColor?.color,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: _paletteGenerator?.darkVibrantColor?.color,
          // indicatorColor: const Color(0xFF341010),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        chipTheme: ChipThemeData(
          labelPadding: const EdgeInsets.symmetric(horizontal: 11),
          selectedColor: const Color(0xFF0066FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF0066FF),
          elevation: 0,
          shape: CircleBorder(),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
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
