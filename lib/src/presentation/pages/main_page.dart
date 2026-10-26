import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/server_addresses_provider.dart';
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
    (Icons.home_outlined, S.of(context).home),
    (JPlayer.play_circle_outlined, S.of(context).browse),
    (JPlayer.settings, S.of(context).settings),
    (JPlayer.download, S.of(context).downloads),
  };

  Widget _collapseButton(bool collapsed) {
    return RailTooltip(
      message: collapsed
          ? S.of(context).expandSidebar
          : S.of(context).collapseSidebar,
      child: IconButton(
        onPressed: () => ref
            .read(appSettingsProvider.notifier)
            .toggle(AppSetting.sidebarCollapsed),
        icon: const Icon(Icons.menu),
        color: _theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _supportButton(bool collapsed) {
    final button = RailItemButton(
      onPressed: () => context.pushNamed(Routes.support.name),
      icon: const Icon(Icons.help_outline),
      label: Text(S.of(context).support),
      foregroundColor: _theme.colorScheme.onPrimary,
      fontSize: 16,
      horizontalPadding: 30,
    );

    return RailTooltip(
      message: S.of(context).support,
      enabled: collapsed,
      child: button,
    );
  }

  Widget _logoutButton(bool collapsed) {
    final button = RailItemButton(
      onPressed: ref.read(authProvider.notifier).logout,
      icon: const Icon(JPlayer.log_out),
      label: Text(S.of(context).logOut),
      foregroundColor: _theme.colorScheme.onPrimary,
      fontSize: 16,
      horizontalPadding: 30,
    );

    return RailTooltip(
      message: S.of(context).logOut,
      enabled: collapsed,
      child: button,
    );
  }

  void _navigateToItem(int index) {
    ref.read(lyricsVisibleProvider.notifier).state = false;
    widget.shell.goBranch(
      index,
      initialLocation: index == widget.shell.currentIndex,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_maybeShowUpdates()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
  }

  Future<void> _maybeShowUpdates() async {
    if (!mounted) return;
    final isDesktop = _device.isDesktop;
    await maybeShowUpdatifyPopup(
      context,
      projectId: updatifyProjectId,
      popupType: isDesktop
          ? UpdatifyPopupType.modal
          : UpdatifyPopupType.bottomSheet,
      backgroundColor: Themes.changelogSurface,
      title: S.of(context).whatsNew,
      borderRadius: BorderRadius.circular(8),
      width: isDesktop ? MediaQuery.sizeOf(context).width / 2 : null,
    );
  }

  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (!await review.isAvailable()) return;
      await ref.read(reviewPromptProvider.notifier).markPrompted();
      await review.requestReview();
    } on PlatformException {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(reviewPromptProvider, (_, due) {
      if (due) unawaited(_requestReview());
    });
    final currentIndex = widget.shell.currentIndex;
    final isOffline = ref.watch(isOfflineProvider);
    final pluginNotice = ref.watch(visiblePluginNoticeProvider);
    final update = ref.watch(visibleUpdateProvider);
    final hasBanner = isOffline || pluginNotice != null || update != null;
    final sidebarCollapsed = ref.watch(
      settingProvider(AppSetting.sidebarCollapsed),
    );

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
                  collapsed: sidebarCollapsed,
                  selectedItemColor: _theme.colorScheme.primary,
                  unselectedItemColor: _theme.colorScheme.onPrimary,
                  selectedFontSize: 16,
                  unselectedFontSize: 16,
                  leading: Row(
                    children: [
                      const CollapsibleLabel(
                        alignment: Alignment.centerLeft,
                        slide: 0,
                        child: Text(
                          'JellyBox',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _collapseButton(sidebarCollapsed),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _supportButton(sidebarCollapsed),
                      _logoutButton(sidebarCollapsed),
                    ],
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
                    if (isOffline)
                      const OfflineBanner()
                    else if (pluginNotice != null)
                      PluginNoticeBanner(notice: pluginNotice)
                    else if (update != null)
                      UpdateBanner(update: update),
                    Expanded(
                      child: Builder(
                        builder: (context) => MediaQuery.removePadding(
                          context: context,
                          removeTop: hasBanner,
                          child: Stack(
                            children: [
                              widget.shell,
                              if (_device.isDesktop)
                                const Positioned.fill(child: LyricsOverlay()),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const BottomPlayer(),
                    const PlayingElsewhereStrip(),
                  ],
                ),
              ),
            ],
          ),
          if (_device.isDesktop) const Positioned.fill(child: QueueSidebar()),
          if (showsDesktopTitleBar)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DesktopTitleBar(),
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

    final content = Stack(
      children: [
        scaffold,
        const Positioned.fill(child: StudioMode()),
      ],
    );

    return WindowResizeFrame(child: content);
  }
}
