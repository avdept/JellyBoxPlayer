import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class PlayerSongView extends StatelessWidget {
  const PlayerSongView({
    required this.name,
    required this.singer,
    this.isPlaying = false,
    this.isFavorite = false,
    this.downloadProgress,
    this.onTap,
    this.onLikePressed,
    super.key,
  });

  final String name;
  final String singer;
  final bool isPlaying;
  final bool isFavorite;
  final double? downloadProgress;
  final VoidCallback? onTap;
  final VoidCallback? onLikePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SimpleListTile(
        backgroundColor: isPlaying
            ? theme.bottomSheetTheme.backgroundColor?.withOpacity(0.75)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: isMobile ? 16 : 30,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        subtitle: Text(
          singer,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            height: 1.2,
          ),
        ),
        trailing: Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (downloadProgress != null)
              SizedBox.square(
                dimension: 30,
                child: CircularProgressIndicator(
                  value: downloadProgress,
                  color: const Color(0xFF0066FF),
                  backgroundColor: theme.colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              ),
            if (isDesktop)
              IconButton(
                onPressed: onLikePressed,
                icon: Icon(
                  CupertinoIcons.heart,
                  color: theme.colorScheme.onPrimary,
                ),
                selectedIcon: Icon(
                  CupertinoIcons.heart_fill,
                  color: theme.colorScheme.primary,
                ),
                isSelected: isFavorite,
              ),
          ],
        ),
      ),
    );
  }
}
