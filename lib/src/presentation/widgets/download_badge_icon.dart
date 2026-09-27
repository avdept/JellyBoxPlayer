import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/download_badge_provider.dart';

class DownloadBadgeIcon extends ConsumerWidget {
  const DownloadBadgeIcon({
    required this.item,
    this.size = 22,
    super.key,
  });

  final LibraryItem item;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(downloadBadgeProvider((item.kind, item.id)));
    if (badge == null) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: switch (badge) {
        DownloadBadge.downloaded => Icon(
          Icons.cloud_download_sharp,
          color: Colors.white,
          size: size * 0.65,
        ),
        DownloadBadge.downloading => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: size - 2,
              child: CircularProgressIndicator(
                value: ref.watch(downloadProgressProvider(item.id)),
                strokeWidth: 2,
                color: Colors.grey,
                backgroundColor: Colors.white24,
              ),
            ),
            Icon(JPlayer.download, color: Colors.grey, size: size * 0.5),
          ],
        ),
      },
    );
  }
}
