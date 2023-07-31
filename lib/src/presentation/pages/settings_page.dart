import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final deviceType = getDeviceType(screenSize);
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return Scaffold(
      body: SafeArea(
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
                ),
              ),
              Wrap(
                direction: Axis.vertical,
                children: [
                  _librariesButton(),
                  if (!isDesktop) _logOutButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _librariesButton() => TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.music_note),
        label: const Text('Music libraries'),
      );

  Widget _logOutButton() => TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.logout),
        label: const Text('Log out'),
      );
}
