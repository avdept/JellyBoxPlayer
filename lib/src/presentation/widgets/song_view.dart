import 'package:flutter/material.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SongView extends StatelessWidget {
  const SongView({
    required this.name,
    this.onTap,
    this.onOptionsPressed,
    super.key,
  });

  final String name;
  final VoidCallback? onTap;
  final VoidCallback? onOptionsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isTablet = deviceType == DeviceScreenType.tablet;

    return SimpleListTile(
      onTap: onTap,
      leading: Image(
        image: const AssetImage(Images.songSample),
        width: isMobile ? 42 : 50,
        height: isMobile ? 42 : 50,
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
        'Song',
        style: TextStyle(
          fontSize: isTablet ? 16 : 12,
          height: 1.2,
          color: theme.colorScheme.onPrimary.withOpacity(0.61),
        ),
      ),
      trailing: IconButton(
        onPressed: onOptionsPressed,
        icon: const Icon(JPlayer.more_horizontal),
      ),
      leadingToTitle: isMobile ? 6 : 16,
    );
  }
}
