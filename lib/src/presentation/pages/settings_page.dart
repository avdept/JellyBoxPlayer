import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _onLibrariesPressed(BuildContext context) =>
      context.pushNamed(Routes.library.name);

  void _onPaletteSettingsPressed(BuildContext context) =>
      context.pushNamed(Routes.palette.name);

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
    icon: const Icon(JPlayer.music),
    label: const Text('Palette settings'),
  );

  Widget _librariesButton(BuildContext context) => TextButton.icon(
    onPressed: () => _onLibrariesPressed(context),
    icon: const Icon(JPlayer.music),
    label: const Text('Music libraries'),
  );

  Widget _logOutButton(WidgetRef ref) => TextButton.icon(
    onPressed: ref.read(authProvider.notifier).logout,
    icon: const Icon(JPlayer.log_out),
    label: const Text('Log out'),
  );
}
