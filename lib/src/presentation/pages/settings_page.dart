import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _onLibrariesPressed(BuildContext context) => context.go(Routes.library);
  void _onPaletteSettingsPressed(BuildContext context) {
    final location = GoRouterState.of(context).fullPath;
    context.go('$location${Routes.palette}');
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;
    final contentPadding = EdgeInsets.only(
      left: padding.left + (isMobile ? 16 : 30),
      top: padding.top + (isMobile ? 16 : 30),
      right: padding.right + (isMobile ? 16 : 30),
      bottom: isMobile ? 22 : 26,
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
                    fontSize: isMobile ? 24 : 36,
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
                  if (!isDesktop) _logOutButton(),


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

  Widget _logOutButton() => TextButton.icon(
        onPressed: () {},
        icon: const Icon(JPlayer.log_out),
        label: const Text('Log out'),
      );
}
