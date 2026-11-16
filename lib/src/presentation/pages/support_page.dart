import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/pages/settings/support_settings.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

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
                'Support',
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
      slivers: const [
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topLeft,
            child: SupportSettings(),
          ),
        ),
      ],
    );
  }
}
