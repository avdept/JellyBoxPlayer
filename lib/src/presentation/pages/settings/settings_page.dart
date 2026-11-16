import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/pages/settings/about_settings.dart';
import 'package:jplayer/src/presentation/pages/settings/connection_settings.dart';
import 'package:jplayer/src/presentation/pages/settings/home_settings.dart';
import 'package:jplayer/src/presentation/pages/settings/integrations_settings.dart';
import 'package:jplayer/src/presentation/pages/settings/interface_settings.dart';
import 'package:jplayer/src/presentation/pages/settings/player_settings.dart';
import 'package:jplayer/src/presentation/pages/settings/servers_settings.dart';
import 'package:jplayer/src/presentation/pages/settings/settings_section.dart';
import 'package:jplayer/src/presentation/pages/settings/support_settings.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

export 'settings_section.dart';

Widget settingsSectionBody(SettingsSection section) => switch (section) {
  SettingsSection.servers => const ServersSettings(),
  SettingsSection.connection => const ConnectionSettings(),
  SettingsSection.home => const HomeSettings(),
  SettingsSection.interface => const InterfaceSettings(),
  SettingsSection.player => const PlayerSettings(),
  SettingsSection.integrations => const IntegrationsSettings(),
  SettingsSection.support => const SupportSettings(),
  SettingsSection.about => const AboutSettings(),
};

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsSection _selected = SettingsSection.servers;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final inset = device.isMobile ? 16.0 : 30.0;
    final contentPadding = EdgeInsets.only(
      left: padding.left + inset,
      top: padding.top + inset,
      right: padding.right + inset,
      bottom: device.isMobile ? 22 : 26,
    );

    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientPanelDecoration(
              child: Padding(
                padding: EdgeInsets.only(
                  left: contentPadding.left,
                  top: contentPadding.top,
                  right: contentPadding.right,
                  bottom: 20,
                ),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: device.isMobile ? 24 : 36,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            Expanded(
              child: device.isMobile
                  ? _sectionLinks(context, device, contentPadding)
                  : _masterDetail(contentPadding),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLinks(
    BuildContext context,
    DeviceType device,
    EdgeInsets contentPadding,
  ) => ListView(
    padding: EdgeInsets.only(
      left: contentPadding.left,
      right: contentPadding.right,
      bottom: contentPadding.bottom,
    ),
    children: [
      for (final section in SettingsSection.values)
        SettingsSectionTile(
          section: section,
          subtitle: section.summary(mobile: device.isMobile),
          onTap: () => context.pushNamed(
            Routes.settingsSection.name,
            pathParameters: {'section': section.name},
          ),
        ),
    ],
  );

  Widget _masterDetail(EdgeInsets contentPadding) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: 260,
        child: ListView(
          padding: EdgeInsets.only(
            left: contentPadding.left,
            top: 8,
            bottom: contentPadding.bottom,
          ),
          children: [
            for (final section in SettingsSection.values)
              SettingsSectionTile(
                section: section,
                selected: section == _selected,
                onTap: () => setState(() => _selected = section),
              ),
          ],
        ),
      ),
      const SizedBox(width: 24),
      Expanded(
        child: SingleChildScrollView(
          key: ValueKey(_selected),
          padding: EdgeInsets.only(
            right: contentPadding.right,
            bottom: contentPadding.bottom,
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: settingsSectionBody(_selected),
          ),
        ),
      ),
    ],
  );
}

class SettingsSectionPage extends StatelessWidget {
  const SettingsSectionPage({required this.section, super.key});

  final SettingsSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final horizontalPadding = device.isMobile ? 16.0 : 30.0;
    final navigationBarHeight = device.isMobile ? 56.0 : 64.0;

    return ScrollablePageScaffold(
      useGradientBackground: true,
      navigationBar: PreferredSize(
        preferredSize: Size.fromHeight(navigationBarHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              const BackButton(),
              const SizedBox(width: 4),
              Text(
                section.title,
                style: TextStyle(
                  fontSize: device.isMobile ? 22 : 26,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      contentPadding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: 30,
      ),
      slivers: [SliverToBoxAdapter(child: settingsSectionBody(section))],
    );
  }
}

class SettingsSectionTile extends StatefulWidget {
  const SettingsSectionTile({
    required this.section,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    super.key,
  });

  final SettingsSection section;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<SettingsSectionTile> createState() => _SettingsSectionTileState();
}

class _SettingsSectionTileState extends State<SettingsSectionTile> {
  var _hovered = false;
  var _pressed = false;

  bool get _compact => widget.subtitle == null;

  double get _backgroundAlpha {
    if (_pressed) return 0.16;
    if (widget.selected) return _hovered ? 0.14 : 0.12;
    if (_hovered) return 0.06;
    return _compact ? 0 : 0.06;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final radius = BorderRadius.circular(6);
    return Padding(
      padding: EdgeInsets.only(top: _compact ? 4 : 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: onPrimary.withValues(alpha: _backgroundAlpha),
              borderRadius: radius,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: _compact ? 10 : 14,
            ),
            child: Row(
              children: [
                Icon(
                  widget.section.icon,
                  size: _compact ? 20 : 26,
                  color: widget.selected
                      ? theme.colorScheme.primary
                      : onPrimary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.section.title,
                        style: TextStyle(
                          fontSize: _compact ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: onPrimary,
                        ),
                      ),
                      if (widget.subtitle case final subtitle?)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: onPrimary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_compact)
                  Icon(
                    Icons.chevron_right,
                    color: onPrimary.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
