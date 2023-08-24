import 'package:flutter/material.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class DownloadedAlbumView extends StatelessWidget {
  const DownloadedAlbumView({
    required this.name,
    required this.size,
    this.onTap,
    this.onDeletePressed,
    super.key,
  });

  final String name;
  final String size;
  final VoidCallback? onTap;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Offstage(
              offstage: !isDesktop,
              child: AspectRatio(
                aspectRatio: 1,
                child: Ink.image(
                  image: const AssetImage(Images.albumSample),
                ),
              ),
            ),
            SimpleListTile(
              leading: Offstage(
                offstage: isDesktop,
                child: Ink.image(
                  image: const AssetImage(Images.albumSample),
                  width: constraints.maxHeight,
                  height: constraints.maxHeight,
                ),
              ),
              title: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  color: theme.colorScheme.onPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
              subtitle: Text(
                size,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  color: theme.colorScheme.onPrimary.withOpacity(0.61),
                ),
              ),
              trailing: IconButton(
                onPressed: onDeletePressed,
                padding: EdgeInsets.zero,
                icon: const Icon(JPlayer.trash_2),
              ),
              leadingToTitle: isDesktop ? 0 : (isMobile ? 6 : 16),
            ),
          ],
        ),
      ),
    );
  }
}
