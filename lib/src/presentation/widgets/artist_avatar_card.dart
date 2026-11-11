import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_card_metrics.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ArtistAvatarCard extends StatelessWidget {
  const ArtistAvatarCard({
    required this.name,
    required this.size,
    this.image,
    this.subtitle,
    this.badge,
    this.onTap,
    this.optionsBuilder,
    super.key,
  });

  static const nameFontSize = 15.0;
  static const subtitleFontSize = 12.0;
  static const textBlockHeight = 52.0;

  static double avatarSize(DeviceType device) =>
      AlbumCardMetrics.carouselWidth(device) * 0.8;

  static double cardHeight(double size) => size + textBlockHeight;

  static SliverGridDelegate gridDelegate(DeviceType device) {
    final avatar = avatarSize(device);
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: avatar,
      mainAxisSpacing: AlbumCardMetrics.mainAxisSpacing(device),
      crossAxisSpacing: AlbumCardMetrics.crossAxisSpacing(device),
      childAspectRatio: avatar / cardHeight(avatar),
    );
  }

  final String name;
  final double size;
  final ImageProvider? image;
  final String? subtitle;
  final Widget? badge;
  final VoidCallback? onTap;
  final List<ContextMenuAction> Function(BuildContext)? optionsBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop =
        getDeviceType(MediaQuery.sizeOf(context)) == DeviceScreenType.desktop;
    final options = optionsBuilder;

    return GestureDetector(
      onTap: onTap,
      onLongPress: (!isDesktop && options != null)
          ? () => showLongPressContextMenuSheet(
              context,
              actions: options(context),
            )
          : null,
      onSecondaryTapUp: options != null
          ? (details) => showContextMenu(
              context,
              position: details.globalPosition,
              actions: options(context),
            )
          : null,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: size,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipOval(
                    child: Image(
                      image: image ?? const AssetImage(Images.artistSample),
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        Images.artistSample,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: size * 0.04,
                      right: size * 0.04,
                      child: badge!,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
