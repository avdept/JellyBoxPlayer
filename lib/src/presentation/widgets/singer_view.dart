import 'package:flutter/material.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SingerView extends StatelessWidget {
  const SingerView({
    required this.name,
    this.onTap,
    super.key,
  });

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isTablet = deviceType == DeviceScreenType.tablet;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SimpleListTile(
        leading: Image(
          image: const AssetImage(Images.artistSample),
          width: isMobile ? 42 : 80,
          height: isMobile ? 42 : 80,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            height: 1.2,
            color: theme.colorScheme.onPrimary,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 1,
        ),
        subtitle: Text(
          'Artist',
          style: TextStyle(
            fontSize: isTablet ? 16 : 12,
            height: 1.2,
            color: theme.colorScheme.onPrimary.withOpacity(0.61),
          ),
        ),
        trailing: const Icon(JPlayer.chevron_right),
        leadingToTitle: isMobile ? 6 : (isTablet ? 16 : 20),
      ),
    );
  }
}
