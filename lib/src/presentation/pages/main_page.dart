import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  Set<(IconData, String, String)> get _menuItems => {
        (Icons.play_circle_outline, 'Listen', Routes.listen),
        (Icons.search, 'Search', Routes.search),
        (Icons.settings, 'Settings', Routes.settings),
        (Icons.download, 'Downloads', Routes.downloads),
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
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getLocationIndex(_router.uri.toString());
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return Scaffold(
      body: Row(
        children: [
          Visibility(
            visible: isDesktop,
            child: CustomNavigationRail(
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
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
                style: TextButton.styleFrom(
                  foregroundColor: _theme.colorScheme.onPrimary,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              selectedIndex: currentIndex,
              onDestinationSelected: _navigateToItem,
              destinations: List.generate(
                _menuItems.length,
                (index) => NavigationRailDestination(
                  icon: Icon(_menuItems.elementAt(index).$1),
                  label: Text(_menuItems.elementAt(index).$2),
                  indicatorColor: const Color(0xFF341010),
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
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
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _theme.colorScheme.primary,
          unselectedItemColor: _theme.colorScheme.onPrimary,
          selectedFontSize: 12,
          iconSize: isMobile ? 28 : 60,
          currentIndex: currentIndex ?? 0,
          onTap: _navigateToItem,
          items: List.generate(
            _menuItems.length,
            (index) => BottomNavigationBarItem(
              icon: Icon(_menuItems.elementAt(index).$1),
              label: _menuItems.elementAt(index).$2,
            ),
          ),
          landscapeLayout: isMobile
              ? BottomNavigationBarLandscapeLayout.spread
              : BottomNavigationBarLandscapeLayout.centered,
        ),
      ),
    );
  }
}
