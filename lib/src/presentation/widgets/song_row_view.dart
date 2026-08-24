import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/core/enums/download_status.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SongRowViewKeys {
  const SongRowViewKeys({
    required this.downloadedIcon,
    required this.downloadProgressIndicator,
  });

  final Key downloadedIcon;
  final Key downloadProgressIndicator;
}

class SongRowView extends ConsumerWidget {
  const SongRowView({
    required this.song,
    this.isPlaying = false,
    this.onTap,
    this.onLikePressed,
    this.onArtistTap,
    this.optionsBuilder,
    this.position,
    this.showDownloadState = false,
    this.edgePadding,
    this.testKeys,
    super.key,
  });

  final LibraryItem song;
  final bool isPlaying;
  final void Function(LibraryItem)? onTap;
  final void Function(LibraryItem)? onLikePressed;
  final void Function(LibraryItem)? onArtistTap;
  final List<PopupMenuEntry<void>> Function(BuildContext)? optionsBuilder;

  final int? position;

  final bool showDownloadState;

  final double? edgePadding;

  final SongRowViewKeys? testKeys;

  String get formattedDuration {
    final duration = song.duration;
    final negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return '$negativeSign${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$twoDigitMinutes:$twoDigitSeconds';
  }

  ImageProvider _coverImage(WidgetRef ref) {
    final tag = song.images.primary;
    if (tag != null) {
      return ref.read(imageServiceProvider).albumIP(tagId: tag, id: song.primaryImageId);
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
    final horizontal = edgePadding ?? 0;
    final isDownloaded = showDownloadState
        ? ref.watch(isSongDownloadedProvider(song)).valueOrNull
        : null;
    final currentTask = showDownloadState
        ? ref.watch(downloadServiceProvider).getTask(song.id)
        : null;

    return SimpleListTile(
      onTap: onTap != null ? () => onTap!(song) : null,
      backgroundColor: isPlaying
          ? theme.bottomSheetTheme.backgroundColor?.withOpacity(0.75)
          : Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        horizontal,
        8,
        optionsBuilder != null ? 4 : horizontal,
        8,
      ),
      leading: position != null
          ? Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text('$position'),
            )
          : ClipRRect(
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
          if (currentTask != null)
            ValueListenableBuilder<DownloadStatus>(
              valueListenable: currentTask.status,
              builder: (context, status, _) {
                if (isDownloaded ?? false) {
                  return Icon(
                    Icons.check_circle,
                    key: testKeys?.downloadedIcon,
                    color: Colors.green,
                  );
                }
                if (!currentTask.isDownloadingNow) {
                  return const SizedBox.shrink();
                }
                return SizedBox.square(
                  dimension: 30,
                  child: ValueListenableBuilder<double?>(
                    valueListenable: currentTask.progress,
                    builder: (context, progress, _) =>
                        CircularProgressIndicator(
                          key: testKeys?.downloadProgressIndicator,
                          value: progress,
                          color: const Color(0xFF0066FF),
                          backgroundColor: theme.colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                  ),
                );
              },
            )
          else if (isDownloaded ?? false)
            Icon(
              Icons.check_circle,
              key: testKeys?.downloadedIcon,
              color: Colors.green,
            ),
          if (isDesktop)
            IconButton(
              onPressed: onLikePressed != null
                  ? () => onLikePressed!(song)
                  : null,
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
