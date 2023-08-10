import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late GoRouterState _router;
  late ThemeData _theme;
  late Size _screenSize;

  Set<(IconData, String, String)> get _menuItems => {
        (JPlayer.play_circle_outlined, 'Listen', Routes.listen),
        (JPlayer.search, 'Search', Routes.search),
        (JPlayer.settings, 'Settings', Routes.settings),
        (JPlayer.download, 'Downloads', Routes.downloads),
      };

  void _navigateToItem(int index) => context.go(_menuItems.elementAt(index).$3);

  int? _getLocationIndex(String location) {
    for (var index = 0; index < _menuItems.length; index++) {
      final tabRoute = _menuItems.elementAt(index).$3;
      if (location.startsWith(tabRoute)) return index;
    }

    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router = GoRouterState.of(context);
    _theme = Theme.of(context);
    _screenSize = MediaQuery.sizeOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getLocationIndex(_router.uri.toString());
    final deviceType = getDeviceType(_screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return Scaffold(
      body: Row(
        children: [
          Visibility(
            visible: isDesktop,
            child: CustomNavigationRail(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              selectedItemColor: _theme.colorScheme.primary,
              unselectedItemColor: _theme.colorScheme.onPrimary,
              selectedFontSize: 16,
              unselectedFontSize: 16,
              leading: const Text(
                'Logo',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: TextButton.icon(
                onPressed: () {},
                icon: const Icon(JPlayer.log_out),
                label: const Text('Log out'),
              ),
              selectedIndex: currentIndex,
              onDestinationSelected: _navigateToItem,
              destinations: List.generate(
                _menuItems.length,
                (index) => NavigationRailDestination(
                  icon: Icon(_menuItems.elementAt(index).$1),
                  label: Text(_menuItems.elementAt(index).$2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Visibility(
        visible: !isDesktop,
        child: CupertinoTabBar(
          activeColor: _theme.colorScheme.primary,
          inactiveColor: _theme.colorScheme.onPrimary,
          iconSize: isMobile ? 28 : 60,
          height: isMobile ? 56 : 88,
          currentIndex: currentIndex ?? 0,
          onTap: _navigateToItem,
          items: List.generate(
            _menuItems.length,
            (index) => BottomNavigationBarItem(
              icon: Icon(_menuItems.elementAt(index).$1),
              label: _menuItems.elementAt(index).$2,
            ),
          ),
        ),
      ),
    );
  }
}
