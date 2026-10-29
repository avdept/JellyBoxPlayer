import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/lidarr_provider.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/lidarr_add_sheet.dart';
import 'package:responsive_builder/responsive_builder.dart';

export 'package:jplayer/src/domain/providers/lidarr_provider.dart'
    show LidarrAlbumTarget, LidarrArtistTarget, LidarrTarget;

List<ContextMenuAction> catalogItemActions(
  BuildContext context,
  LidarrTarget target,
) => [
  ContextMenuAction(
    entry: ContextMenuEntry.addToLidarr,
    icon: const Icon(Icons.library_add_outlined),
    label: const Text('Add to Lidarr'),
    run: () => showLidarrAddSheet(context, target),
  ),
];

class CatalogContextMenuRegion extends ConsumerWidget {
  const CatalogContextMenuRegion({
    required this.child,
    this.target,
    this.onTap,
    super.key,
  });

  final Widget child;
  final LidarrTarget? target;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = this.target;
    final enabled = target != null && ref.watch(lidarrAvailableProvider);
    final isDesktop =
        getDeviceType(MediaQuery.sizeOf(context)) == DeviceScreenType.desktop;
    return GestureDetector(
      onTap: onTap,
      onLongPress: isDesktop || !enabled
          ? null
          : () => showLongPressContextMenuSheet(
              context,
              actions: catalogItemActions(context, target),
            ),
      onSecondaryTapUp: enabled
          ? (details) => showContextMenu(
              context,
              position: details.globalPosition,
              actions: catalogItemActions(context, target),
            )
          : null,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class AddToLidarrButton extends ConsumerWidget {
  const AddToLidarrButton({required this.target, super.key});

  final LidarrTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(lidarrAvailableProvider)) return const SizedBox.shrink();
    final status = switch (target) {
      LidarrAlbumTarget(:final album) =>
        ref
            .watch(
              lidarrAlbumStatusProvider((
                upc: album.upc,
                artistName: album.artistName,
              )),
            )
            .valueOrNull,
      LidarrArtistTarget(:final artist) =>
        ref.watch(lidarrArtistStatusProvider(artist.name)).valueOrNull,
    };
    final (label, icon) = switch (status?.state) {
      null || LidarrEntityState.notAdded => (
        'Add to Lidarr',
        Icons.library_add_outlined,
      ),
      LidarrEntityState.added => (
        switch (target) {
          LidarrArtistTarget() => 'Already in Lidarr',
          LidarrAlbumTarget() => 'In Lidarr',
        },
        Icons.library_add_check,
      ),
    };
    final color = Theme.of(context).colorScheme.onPrimary;
    return OutlinedButton.icon(
      onPressed: () => unawaited(showLidarrAddSheet(context, target)),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
    );
  }
}
