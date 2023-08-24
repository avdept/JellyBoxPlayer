import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _onLibrariesPressed(BuildContext context) => context.go(Routes.library);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          minimum: EdgeInsets.all(isMobile ? 16 : 30),
          child: Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 22 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 36,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  direction: Axis.vertical,
                  spacing: 4,
                  children: [
                    _librariesButton(context),
                    if (!isDesktop) _logOutButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
