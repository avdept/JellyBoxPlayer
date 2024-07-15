import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

class PlayerSongView extends ConsumerWidget {
  const PlayerSongView({
    required this.song,
    required this.position,
    this.isPlaying = false,
    this.downloadProgress,
    this.onTap,
    this.onLikePressed,
    this.optionsBuilder,
    super.key,
  });

  final SongDTO song;
  final bool isPlaying;
  final double? downloadProgress;
  final VoidCallback? onTap;
  final VoidCallback? onLikePressed;
  final List<PopupMenuEntry<void>> Function(BuildContext)? optionsBuilder;
  final int position;

  Duration get duration {
    return Duration(milliseconds: (song.runTimeTicks / 10000).ceil());
  }

  String get formattedDuration {
    final negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return '$negativeSign${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          song.name ?? '',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        subtitle: Text(
          song.albumArtist ?? '',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            height: 1.2,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Text(position.toString()),
        ),
        trailing: Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(formattedDuration),
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
                isSelected: song.songUserData.isFavorite,
              ),
            if (optionsBuilder != null)
              PopupMenuButton<void>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More',
                itemBuilder: optionsBuilder!,
              ),
          ],
        ),
      ),
    );
  }
}
