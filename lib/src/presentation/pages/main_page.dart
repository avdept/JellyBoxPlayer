import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
class MainPage extends ConsumerStatefulWidget {
  const MainPage({
    required this.shell,
    super.key,
  });

  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late ThemeData _theme;
  late DeviceType _device;

  Set<(IconData, String)> get _menuItems => {
        (JPlayer.play_circle_outlined, 'Listen'),
        (JPlayer.search, 'Search'),
        (JPlayer.like, 'Favorites'),
        (JPlayer.settings, 'Settings'),
        // (JPlayer.download, 'Downloads'),
      };

  void _navigateToItem(int index) => widget.shell.goBranch(
        index,
        initialLocation: index == widget.shell.currentIndex,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.shell.currentIndex;

    return Scaffold(
      body: Row(
        children: [
          Visibility(
            visible: _device.isDesktop,
            child: CustomNavigationRail(
              padding: const EdgeInsets.symmetric(
                vertical: 30,
                horizontal: 20,
              ),
              selectedItemColor: _theme.colorScheme.primary,
              unselectedItemColor: _theme.colorScheme.onPrimary,
              selectedFontSize: 16,
              unselectedFontSize: 16,
              leading: const Text(
                'JellyBox',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: TextButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                },
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
                  indicatorColor: const Color(0xFF341010),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 10,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(child: widget.shell),
                const BottomPlayer(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Visibility(
        visible: !_device.isDesktop,
        child: CupertinoTabBar(
          activeColor: _theme.colorScheme.primary,
          inactiveColor: _theme.colorScheme.onPrimary,
          iconSize: _device.isMobile ? 28 : 24,
          height: _device.isMobile ? 56 : 50,
          currentIndex: currentIndex,
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
