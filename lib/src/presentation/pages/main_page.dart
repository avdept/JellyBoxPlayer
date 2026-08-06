import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

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
    (JPlayer.settings, 'Settings'),
    (JPlayer.download, 'Downloads'),
  };

  void _navigateToItem(int index) {
    ref.read(lyricsVisibleProvider.notifier).state = false;
    widget.shell.goBranch(
      index,
      initialLocation: index == widget.shell.currentIndex,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.shell.currentIndex;
    final isOffline = ref.watch(isOfflineProvider);

    final scaffold = Scaffold(
      body: Stack(
        children: [
          Row(
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
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'JellyBox',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      UpdatifyTrigger(
                        projectId: '0ebf56de-26b5-4107-bc87-1aa89b328924',
                        borderRadius: BorderRadius.circular(8),
                        width: _device.isDesktop
                            ? MediaQuery.sizeOf(context).width / 2
                            : double.infinity,
                      ),
                    ],
                  ),
                  trailing: TextButton.icon(
                    onPressed: ref.read(authProvider.notifier).logout,
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
                    if (isOffline) const OfflineBanner(),
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: isOffline,
                        child: Stack(
                          children: [
                            widget.shell,
                            if (_device.isDesktop)
                              const Positioned.fill(child: LyricsOverlay()),
                          ],
                        ),
                      ),
                    ),
                    const BottomPlayer(),
                  ],
                ),
              ),
            ],
          ),
          Visibility(
            visible: Platform.isLinux,
            child: WindowTitleBarBox(
              child: Row(
                children: [
                  Expanded(
                    child: MoveWindow(),
                  ),
                  MinimizeWindowButton(),
                  MaximizeWindowButton(),
                  CloseWindowButton(),
                ],
              ),
            ),
          ),
          if (Platform.isWindows)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: WindowsTitleBar(),
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

    if (_device.isMobile) return scaffold;

    return Stack(
      children: [
        scaffold,
        const Positioned.fill(child: StudioMode()),
      ],
    );
  }
}
