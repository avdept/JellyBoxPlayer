import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SongRowView extends ConsumerWidget {
  const SongRowView({
    required this.song,
    this.isPlaying = false,
    this.onTap,
    this.onLikePressed,
    this.onArtistTap,
    this.optionsBuilder,
    super.key,
  });

  final ItemDTO song;
  final bool isPlaying;
  final void Function(ItemDTO)? onTap;
  final void Function(ItemDTO)? onLikePressed;
  final void Function(ItemDTO)? onArtistTap;
  final List<PopupMenuEntry<void>> Function(BuildContext)? optionsBuilder;

  String get formattedDuration {
    final duration = Duration(milliseconds: (song.runTimeTicks / 10000).ceil());
    final negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return '$negativeSign${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds';
  }

  ImageProvider _coverImage(WidgetRef ref) {
    final tag = song.imageTags['Primary'];
    if (tag != null) {
      return ref.read(imageServiceProvider).albumIP(tagId: tag, id: song.id);
    }
    return const AssetImage(Images.album);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isTablet = deviceType == DeviceScreenType.tablet;
    final isDesktop = deviceType == DeviceScreenType.desktop;
    final imageSize = isMobile ? 46.0 : 56.0;

    return SimpleListTile(
      onTap: onTap != null ? () => onTap!(song) : null,
      backgroundColor: isPlaying
          ? theme.bottomSheetTheme.backgroundColor?.withOpacity(0.75)
          : Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        optionsBuilder != null ? 4 : 0,
        8,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image(
          image: _coverImage(ref),
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
        ),
      ),
      leadingToTitle: isMobile ? 12 : 16,
      title: Text(
        song.name,
        style: TextStyle(
          fontSize: isTablet ? 18 : 14,
          fontWeight: FontWeight.w600,
          height: 1.2,
          overflow: TextOverflow.ellipsis,
        ),
        maxLines: 1,
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClickableWidget(
            onPressed: (onArtistTap != null && song.albumArtists.isNotEmpty)
                ? () => onArtistTap!(song)
                : null,
            textStyle: TextStyle(
              fontSize: isTablet ? 16 : 12,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: theme.colorScheme.onPrimary.withOpacity(0.6),
              overflow: TextOverflow.ellipsis,
            ),
            child: Text(song.albumArtist ?? '', maxLines: 1),
          ),
        ],
      ),
      trailing: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            formattedDuration,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: theme.colorScheme.onPrimary.withOpacity(0.6),
            ),
          ),
          if (isDesktop)
            IconButton(
              onPressed:
                  onLikePressed != null ? () => onLikePressed!(song) : null,
              icon: Icon(
                CupertinoIcons.heart,
                color: theme.colorScheme.onPrimary,
              ),
              selectedIcon: Icon(
                CupertinoIcons.heart_fill,
                color: theme.colorScheme.primary,
              ),
              isSelected: song.userData.isFavorite,
            ),
          if (optionsBuilder != null)
            PopupMenuButton<void>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More',
              itemBuilder: optionsBuilder!,
            ),
        ],
      ),
    );
  }
}
