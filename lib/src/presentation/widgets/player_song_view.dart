import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

@visibleForTesting
class PlayerSongViewKeys {
  @visibleForTesting
  const PlayerSongViewKeys({
    required this.downloadedIcon,
    required this.downloadProgressIndicator,
  });

  final Key downloadedIcon;
  final Key downloadProgressIndicator;
}

class PlayerSongView extends ConsumerWidget {
  const PlayerSongView({
    required this.song,
    required this.position,
    this.isPlaying = false,
    this.onTap,
    this.onLikePressed,
    this.optionsBuilder,
    @visibleForTesting this.testKeys,
    super.key,
  });

  final SongDTO song;
  final bool isPlaying;
  final void Function(SongDTO)? onTap;
  final void Function(SongDTO)? onLikePressed;
  final List<PopupMenuEntry<void>> Function(BuildContext)? optionsBuilder;
  final int position;
  final PlayerSongViewKeys? testKeys;

  String get formattedDuration {
    final duration = Duration(milliseconds: (song.runTimeTicks / 10000).ceil());
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
    final isDownloaded = ref.watch(isSongDownloadedProvider(song)).valueOrNull;
    final currentTask = ref.read(downloadServiceProvider).getTask(song.id);

    return SimpleListTile(
      onTap: (onTap != null) ? () => onTap!.call(song) : null,
      backgroundColor: isPlaying
          ? theme.bottomSheetTheme.backgroundColor?.withOpacity(0.75)
          : Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 30,
        12,
        (optionsBuilder != null) ? 4 : (isMobile ? 16 : 30),
        12,
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
        padding: const EdgeInsets.only(right: 10),
        child: Text(position.toString()),
      ),
      trailing: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(formattedDuration),
          if (isDownloaded ?? false)
            Icon(
              Icons.check_circle,
              key: testKeys?.downloadedIcon,
              color: Colors.green,
            )
          else if (currentTask?.isDownloadingNow ?? false)
            SizedBox.square(
              dimension: 30,
              child: ValueListenableBuilder(
                valueListenable: currentTask!.progress,
                builder: (context, progress, _) {
                  return CircularProgressIndicator(
                    key: testKeys?.downloadProgressIndicator,
                    value: progress,
                    color: const Color(0xFF0066FF),
                    backgroundColor: theme.colorScheme.onPrimary,
                    strokeWidth: 2,
                  );
                },
              ),
            ),
          if (isDesktop)
            IconButton(
              onPressed: (onLikePressed != null)
                  ? () => onLikePressed!.call(song)
                  : null,
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
    );
  }
}
