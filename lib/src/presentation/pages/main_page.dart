import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/window/mac_title_bar.dart';
import 'package:jplayer/src/providers/dev_tools_provider.dart';
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
    (Icons.home_outlined, 'Home'),
    (JPlayer.play_circle_outlined, 'Browse'),
    (JPlayer.settings, 'Settings'),
    (JPlayer.download, 'Downloads'),
  };

  Widget _collapseButton(bool collapsed) {
    return RailTooltip(
      message: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
      child: IconButton(
        onPressed: () => ref
            .read(appSettingsProvider.notifier)
            .toggle(AppSetting.sidebarCollapsed),
        icon: const Icon(Icons.menu),
        color: _theme.colorScheme.onPrimary,
      ),
    );
  }

  static const _supportBranch = 4;

  Widget _supportButton(bool collapsed) {
    final selected = widget.shell.currentIndex == _supportBranch;
    final button = RailItemButton(
      onPressed: () => _navigateToItem(_supportBranch),
      icon: const Icon(Icons.help_outline),
      label: const Text('Support'),
      foregroundColor: selected
          ? _theme.colorScheme.primary
          : _theme.colorScheme.onPrimary,
      backgroundColor: selected ? AppColors.from(context).indicator : null,
      fontSize: 16,
      horizontalPadding: 30,
    );

    return RailTooltip(
      message: 'Support',
      enabled: collapsed,
      child: button,
    );
  }

  Widget _devButton(bool collapsed) {
    final button = RailItemButton(
      onPressed: () => _pushOnce(Routes.devQueues),
      icon: const Icon(Icons.bug_report_outlined),
      label: const Text('Dev'),
      foregroundColor: _theme.colorScheme.onPrimary,
      fontSize: 16,
      horizontalPadding: 30,
    );

    return RailTooltip(
      message: 'Saved queues (debug)',
      enabled: collapsed,
      child: button,
    );
  }

  Widget _logoutButton(bool collapsed) {
    final button = RailItemButton(
      onPressed: ref.read(authProvider.notifier).logout,
      icon: const Icon(JPlayer.log_out),
      label: const Text('Log out'),
      foregroundColor: _theme.colorScheme.onPrimary,
      fontSize: 16,
      horizontalPadding: 30,
    );

    return RailTooltip(
      message: 'Log out',
      enabled: collapsed,
      child: button,
    );
  }

  void _pushOnce(Routes route) {
    final location = GoRouter.of(context).state.matchedLocation;
    if (location.endsWith('/${route.path}')) return;
    unawaited(context.pushNamed(route.name));
  }

  void _navigateToItem(int index) {
    ref.read(lyricsVisibleProvider.notifier).state = false;
    if (index == 1) ref.read(browseTabSelectedProvider.notifier).state++;
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
      backgroundColor: AppColors.from(context).surface,
      title: changelogTitle,
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

  double _floatingPlayerHeight = 0;

  void _onFloatingPlayerSize(Size size) {
    if (!mounted || size.height == _floatingPlayerHeight) return;
    setState(() => _floatingPlayerHeight = size.height);
  }

  Widget _floatingBody({
    required Widget rail,
    required Widget? banner,
    required bool fullWidth,
    required bool translucent,
    required bool collapsed,
    required Widget Function(BuildContext) pageArea,
  }) {
    const margin = FloatingPanels.margin;
    final hasPlayer = _floatingPlayerHeight > 0;
    final panels = FloatingPanels(
      radius: ref.watch(panelRadiusProvider),
      shadow: AppColors.from(context).isLight
          ? ref.watch(panelShadowProvider)
          : PanelShadow.none,
      contentInsets: fullWidth
          ? EdgeInsets.only(
              left:
                  (collapsed
                      ? CustomNavigationRail.defaultCollapsedWidth
                      : CustomNavigationRail.defaultWidth) +
                  margin * 2,
              bottom: hasPlayer ? _floatingPlayerHeight + margin * 2 : 0,
            )
          : EdgeInsets.zero,
      translucent: translucent,
      overlay: fullWidth,
      child: CustomMultiChildLayout(
        delegate: _FloatingLayout(fullWidth: fullWidth),
        children: [
          LayoutId(
            id: _FloatingSlot.page,
            child: Builder(builder: pageArea),
          ),
          LayoutId(
            id: _FloatingSlot.player,
            child: FloatingPanel(
              clip: false,
              visible: hasPlayer,
              child: SizeReporter(
                onSize: _onFloatingPlayerSize,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BottomPlayer(),
                    PlayingElsewhereStrip(),
                  ],
                ),
              ),
            ),
          ),
          LayoutId(
            id: _FloatingSlot.rail,
            child: FloatingPanel(child: rail),
          ),
        ],
      ),
    );
    if (banner == null) return panels;
    return Column(
      children: [
        banner,
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: panels,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(reviewPromptProvider, (_, due) {
      if (due) unawaited(_requestReview());
    });
    final currentIndex = widget.shell.currentIndex;
    final isOffline = ref.watch(isOfflineProvider);
    final manualOffline = ref.watch(manualOfflineProvider);
    final pluginNotice = ref.watch(visiblePluginNoticeProvider);
    final update = ref.watch(visibleUpdateProvider);
    final hasBanner =
        isOffline || manualOffline || pluginNotice != null || update != null;
    final sidebarCollapsed = ref.watch(
      settingProvider(AppSetting.sidebarCollapsed),
    );

    final panelStyle = ref.watch(panelStyleProvider);
    final floating = _device.isDesktop && panelStyle.isFloating;
    final panelsTranslucent =
        panelStyle != PanelStyle.infiniteFloating ||
        ref.watch(settingProvider(AppSetting.panelTranslucent));
    MacTitleBar.sync(
      floating ? MacTitleBarLayout.floating : MacTitleBarLayout.standard,
    );

    final rail = CustomNavigationRail(
      backgroundColor: floating
          ? FloatingPanels.fill(context, translucent: panelsTranslucent)
          : null,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      collapsed: sidebarCollapsed,
      header: floating
          ? const RailSlot(
              child: LibrarySelectorButton(
                size: 28,
                showName: true,
                collapsible: true,
              ),
            )
          : null,
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
      secondary: ref.watch(settingProvider(AppSetting.pinsEnabled))
          ? const PinnedItemsRailBox()
          : null,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ref.watch(devToolsEnabledProvider)) _devButton(sidebarCollapsed),
          if (floating) ...[
            if (ref.watch(settingProvider(AppSetting.offlineModeToggle)))
              const RailSlot(
                childInset: 8,
                child: OfflineModeButton(iconSize: 24),
              ),
            const RailSlot(
              child: UpdatifyBell(isDesktop: true, iconSize: 24, tapSize: 24),
            ),
          ],
          _supportButton(sidebarCollapsed),
          _logoutButton(sidebarCollapsed),
        ],
      ),
      selectedIndex: currentIndex < _menuItems.length ? currentIndex : null,
      onDestinationSelected: _navigateToItem,
      destinations: List.generate(
        _menuItems.length,
        (index) => NavigationRailDestination(
          icon: Icon(_menuItems.elementAt(index).$1),
          label: Text(_menuItems.elementAt(index).$2),
          indicatorColor: AppColors.from(context).indicator,
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 10,
          ),
        ),
      ),
    );

    final banner = isOffline
        ? const OfflineBanner()
        : manualOffline
        ? const ManualOfflineBanner()
        : pluginNotice != null
        ? PluginNoticeBanner(notice: pluginNotice)
        : update != null
        ? UpdateBanner(update: update)
        : null;

    Widget pageArea(BuildContext context) => MediaQuery.removePadding(
      context: context,
      removeTop: hasBanner,
      child: Stack(
        children: [
          widget.shell,
          if (_device.isDesktop)
            const Positioned.fill(
              child: FloatingInset(bottom: true, child: LyricsOverlay()),
            ),
        ],
      ),
    );

    final body = floating
        ? _floatingBody(
            rail: rail,
            banner: banner,
            fullWidth: panelStyle == PanelStyle.infiniteFloating,
            translucent: panelsTranslucent,
            collapsed: sidebarCollapsed,
            pageArea: pageArea,
          )
        : Row(
            children: [
              Visibility(visible: _device.isDesktop, child: rail),
              Expanded(
                child: Column(
                  children: [
                    ?banner,
                    Expanded(child: Builder(builder: pageArea)),
                    const BottomPlayer(),
                    const PlayingElsewhereStrip(),
                  ],
                ),
              ),
            ],
          );

    final scaffold = Scaffold(
      body: Stack(
        children: [
          body,
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
          currentIndex: min(currentIndex, _menuItems.length - 1),
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

enum _FloatingSlot { page, player, rail }

class _FloatingLayout extends MultiChildLayoutDelegate {
  _FloatingLayout({required this.fullWidth});

  final bool fullWidth;

  @override
  void performLayout(Size size) {
    const margin = FloatingPanels.margin;
    final railHeight = max(0.0, size.height - margin * 2);
    final rail = layoutChild(
      _FloatingSlot.rail,
      BoxConstraints(
        maxWidth: size.width,
        minHeight: railHeight,
        maxHeight: railHeight,
      ),
    );
    positionChild(_FloatingSlot.rail, const Offset(margin, margin));

    final left = rail.width + margin * 2;
    final player = layoutChild(
      _FloatingSlot.player,
      BoxConstraints.tightFor(width: max(0, size.width - left - margin)),
    );
    final bottom = player.height > 0 ? player.height + margin * 2 : 0.0;
    positionChild(
      _FloatingSlot.player,
      Offset(left, size.height - bottom + (player.height > 0 ? margin : 0)),
    );

    if (fullWidth) {
      layoutChild(_FloatingSlot.page, BoxConstraints.tight(size));
      positionChild(_FloatingSlot.page, Offset.zero);
    } else {
      layoutChild(
        _FloatingSlot.page,
        BoxConstraints.tight(
          Size(max(0, size.width - left), max(0, size.height - bottom)),
        ),
      );
      positionChild(_FloatingSlot.page, Offset(left, 0));
    }
  }

  @override
  bool shouldRelayout(_FloatingLayout oldDelegate) =>
      fullWidth != oldDelegate.fullWidth;
}
