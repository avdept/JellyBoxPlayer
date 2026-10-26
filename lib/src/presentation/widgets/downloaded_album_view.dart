import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/utils/bold_name_span.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:responsive_builder/responsive_builder.dart';

@visibleForTesting
class DownloadedAlbumViewKeys {
  @visibleForTesting
  const DownloadedAlbumViewKeys({
    required this.deleteButton,
    required this.confirmationDialog,
  });

  final Key deleteButton;
  final Key confirmationDialog;
}

class DownloadedAlbumView extends StatelessWidget {
  const DownloadedAlbumView({
    required this.album,
    this.onTap,
    this.onDelete,
    this.onPlayPressed,
    @visibleForTesting this.testKeys,
    super.key,
  });

  final DownloadedAlbum album;
  final void Function(DownloadedAlbum)? onTap;
  final FutureOr<void> Function(DownloadedAlbum)? onDelete;
  final Future<void> Function(DownloadedAlbum)? onPlayPressed;
  final DownloadedAlbumViewKeys? testKeys;

  @override
  Widget build(BuildContext context) => DownloadedItemView(
    item: album.item,
    sizeInBytes: album.sizeInBytes,
    onTap: (onTap != null) ? () => onTap!.call(album) : null,
    onDelete: (onDelete != null) ? () => onDelete!.call(album) : null,
    onPlayPressed: (onPlayPressed != null)
        ? () => onPlayPressed!.call(album)
        : null,
    testKeys: testKeys,
  );
}

class DownloadedPlaylistView extends StatelessWidget {
  const DownloadedPlaylistView({
    required this.playlist,
    this.onTap,
    this.onDelete,
    this.onPlayPressed,
    @visibleForTesting this.testKeys,
    super.key,
  });

  final DownloadedPlaylist playlist;
  final void Function(DownloadedPlaylist)? onTap;
  final FutureOr<void> Function(DownloadedPlaylist)? onDelete;
  final Future<void> Function(DownloadedPlaylist)? onPlayPressed;
  final DownloadedAlbumViewKeys? testKeys;

  @override
  Widget build(BuildContext context) => DownloadedItemView(
    item: playlist.item,
    sizeInBytes: playlist.sizeInBytes,
    subtitlePrefix: S.of(context).playlist,
    onTap: (onTap != null) ? () => onTap!.call(playlist) : null,
    onDelete: (onDelete != null) ? () => onDelete!.call(playlist) : null,
    onPlayPressed: (onPlayPressed != null)
        ? () => onPlayPressed!.call(playlist)
        : null,
    testKeys: testKeys,
  );
}

class DownloadedItemView extends ConsumerStatefulWidget {
  const DownloadedItemView({
    required this.item,
    required this.sizeInBytes,
    this.subtitlePrefix,
    this.onTap,
    this.onDelete,
    this.onPlayPressed,
    @visibleForTesting this.testKeys,
    super.key,
  });

  final LibraryItem item;
  final int sizeInBytes;
  final String? subtitlePrefix;
  final VoidCallback? onTap;
  final FutureOr<void> Function()? onDelete;
  final Future<void> Function()? onPlayPressed;
  final DownloadedAlbumViewKeys? testKeys;

  @override
  ConsumerState<DownloadedItemView> createState() => _DownloadedItemViewState();
}

class _DownloadedItemViewState extends ConsumerState<DownloadedItemView> {
  var _isBusy = false;

  Future<void> _onDeletePressed() async {
    final shouldDelete = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog.adaptive(
        key: widget.testKeys?.confirmationDialog,
        title: Text.rich(
          boldNameSpan(
            S.of(context).deleteNameQuestion(widget.item.name),
            widget.item.name,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).no),
          ),
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: Text(S.of(context).yes),
          ),
        ],
      ),
    );
    if ((shouldDelete ?? false) && mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      setState(() => _isBusy = true);
      await widget.onDelete?.call();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(S.current.removedFromDownloads(widget.item.name)),
        ),
      );
      _isBusy = false;
      if (mounted) setState(() {});
    }
  }

  String _formatSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    var size = bytes.toDouble();

    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String get _subtitle {
    final size = _formatSize(widget.sizeInBytes);
    final prefix = widget.subtitlePrefix ?? widget.item.albumArtist;
    return (prefix == null || prefix.isEmpty) ? size : '$prefix • $size';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet =
        getDeviceType(MediaQuery.sizeOf(context)) == DeviceScreenType.tablet;

    return AlbumView(
      album: widget.item,
      onTap: (widget.onTap != null) ? (_) => widget.onTap!.call() : null,
      onPlayPressed: (widget.onPlayPressed != null)
          ? (_) => widget.onPlayPressed!.call()
          : null,
      alignTextStart: true,
      showDownloadBadge: false,
      subtitle: _subtitle,
      trailing: IgnorePointer(
        ignoring: _isBusy,
        child: HoverIconButton(
          key: widget.testKeys?.deleteButton,
          onPressed: (widget.onDelete != null) ? _onDeletePressed : null,
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
            minimumSize: WidgetStatePropertyAll(Size.zero),
            visualDensity: VisualDensity.compact,
          ),
          tooltip: S.of(context).removeDownload,
          iconSize: isTablet ? 24 : 20,
          icon: const Icon(JPlayer.trash_2),
        ),
      ),
    );
  }
}
