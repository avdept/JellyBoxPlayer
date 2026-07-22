import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _updatifyProjectId = '0ebf56de-26b5-4107-bc87-1aa89b328924';

  /// Dark background for the mobile changelog sheet, so it doesn't inherit the
  /// maroon [BottomSheetThemeData] panel color used elsewhere in the app.
  static const _changelogSheetColor = Color(0xFF1C1518);

  /// Title shown on the changelog dialog/sheet (defaults to
  /// "Your recent updates" in updatify_flutter).
  static const _changelogTitle = "What's new";

  /// Padding for the settings buttons so their hover/highlight state has
  /// breathing room (the global [TextButtonThemeData] uses zero padding).
  static const _buttonPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

  ButtonStyle get _buttonStyle => TextButton.styleFrom(
    padding: _buttonPadding,
    // Match the 8px corner radius used by the sidebar navigation rail items.
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  void _onLibrariesPressed(BuildContext context) =>
      context.pushNamed(Routes.library.name);

  void _onPaletteSettingsPressed(BuildContext context) =>
      context.pushNamed(Routes.palette.name);

  void _onChangelogPressed(BuildContext context, DeviceType device) {
    if (device.isDesktop) {
      unawaited(
        showUpdatifyDialog(
          context,
          projectId: _updatifyProjectId,
          borderRadius: BorderRadius.circular(8),
          width: device.isDesktop ? MediaQuery.sizeOf(context).width / 2 : double.infinity,
          title: _changelogTitle,
        ),
      );
    } else {
      unawaited(
        showUpdatifyBottomSheet(
          context,
          projectId: _updatifyProjectId,
          backgroundColor: _changelogSheetColor,
          title: _changelogTitle,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = MediaQuery.paddingOf(context);
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final contentPadding = EdgeInsets.only(
      left: padding.left + (device.isMobile ? 16 : 30),
      top: padding.top + (device.isMobile ? 16 : 30),
      right: padding.right + (device.isMobile ? 16 : 30),
      bottom: device.isMobile ? 22 : 26,
    );

    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Padding(
              padding: EdgeInsets.only(
                left: contentPadding.left,
                right: contentPadding.right,
              ),
              child: Wrap(
                direction: Axis.vertical,
                spacing: 4,
                children: [
                  _librariesButton(context),
                  if (kDebugMode) _settingsButton(context),
                  _changelogButton(context, device),
                  if (!device.isDesktop) _logOutButton(ref),
                ],
              ),
            ),
            SizedBox(height: contentPadding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _settingsButton(BuildContext context) => TextButton.icon(
    onPressed: () => _onPaletteSettingsPressed(context),
    style: _buttonStyle,
    icon: const Icon(JPlayer.music),
    label: const Text('Palette settings'),
  );

  Widget _librariesButton(BuildContext context) => TextButton.icon(
    onPressed: () => _onLibrariesPressed(context),
    style: _buttonStyle,
    icon: const Icon(JPlayer.music),
    label: const Text('Music libraries'),
  );

  Widget _changelogButton(BuildContext context, DeviceType device) {
    return TextButton.icon(
      onPressed: () => _onChangelogPressed(context, device),
      style: _buttonStyle,
      icon: const Icon(Icons.history),
      label: const Text('Changelog'),
    );
  }

  Widget _logOutButton(WidgetRef ref) => TextButton.icon(
    onPressed: ref.read(authProvider.notifier).logout,
    style: _buttonStyle,
    icon: const Icon(JPlayer.log_out),
    label: const Text('Log out'),
  );
}
