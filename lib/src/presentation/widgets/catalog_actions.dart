import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/lidarr_provider.dart';
import 'package:jplayer/src/presentation/widgets/adaptive_dialog_action.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/lidarr_add_sheet.dart';
import 'package:optional_features/lidarr.dart';
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
    this.actionsBuilder,
    this.onTap,
    super.key,
  });

  final Widget child;
  final LidarrTarget? target;
  final List<ContextMenuAction> Function(BuildContext context)? actionsBuilder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = this.target;
    final actions =
        actionsBuilder ??
        (target != null && ref.watch(lidarrAddVisibleProvider)
            ? (context) => catalogItemActions(context, target)
            : null);
    final isDesktop =
        getDeviceType(MediaQuery.sizeOf(context)) == DeviceScreenType.desktop;
    return GestureDetector(
      onTap: onTap,
      onLongPress: isDesktop || actions == null
          ? null
          : () => showLongPressContextMenuSheet(
              context,
              actions: actions(context),
            ),
      onSecondaryTapUp: actions != null
          ? (details) => showContextMenu(
              context,
              position: details.globalPosition,
              actions: actions(context),
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
    if (!ref.watch(lidarrAddVisibleProvider)) return const SizedBox.shrink();
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
          LidarrAlbumTarget() => 'In Lidarr, not monitored',
        },
        Icons.library_add_check,
      ),
      LidarrEntityState.monitored => ('Monitored', Icons.schedule),
      LidarrEntityState.downloading => (
        'Adding ${((status?.progress ?? 0) * 100).round()}%',
        Icons.hourglass_top,
      ),
      LidarrEntityState.downloaded => ('Added', Icons.check),
    };
    final color = Theme.of(context).colorScheme.onPrimary;
    final albumId = status?.albumId;
    final canSearch =
        status?.state == LidarrEntityState.monitored && albumId != null;
    ButtonStyle style({BorderRadius? radius}) => OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      shape: radius == null
          ? null
          : RoundedRectangleBorder(borderRadius: radius),
    );
    final main = OutlinedButton.icon(
      onPressed: () => unawaited(showLidarrAddSheet(context, target)),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: style(
        radius: canSearch
            ? const BorderRadius.horizontal(left: Radius.circular(20))
            : null,
      ),
    );
    if (!canSearch) return main;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        main,
        Transform.translate(
          offset: const Offset(-1, 0),
          child: OutlinedButton(
            onPressed: () => unawaited(_confirmSearch(context, ref, albumId)),
            style:
                style(
                  radius: const BorderRadius.horizontal(
                    right: Radius.circular(20),
                  ),
                ).copyWith(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            child: const Tooltip(
              message: 'Search again',
              child: Icon(Icons.refresh, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSearch(
    BuildContext context,
    WidgetRef ref,
    int albumId,
  ) async {
    final title = switch (target) {
      LidarrAlbumTarget(:final album) => album.title,
      LidarrArtistTarget(:final artist) => artist.name,
    };
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog.adaptive(
        title: Text.rich(
          TextSpan(
            text: 'Ask Lidarr to search for ',
            children: [
              TextSpan(
                text: '"$title"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' again?'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(lidarrAdderProvider).searchAlbum(albumId);
      messenger.showSnackBar(
        SnackBar(content: Text('Lidarr is searching for "$title"')),
      );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error is LidarrException
                ? error.message
                : 'Lidarr request failed: $error',
          ),
        ),
      );
    }
  }
}
