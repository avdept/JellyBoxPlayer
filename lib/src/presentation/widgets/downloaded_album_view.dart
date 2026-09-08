import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/domain/models/models.dart';
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
    subtitlePrefix: 'Playlist',
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
    final shouldDelete = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        key: widget.testKeys?.confirmationDialog,
        title: Text.rich(
          TextSpan(
            text: 'Delete ',
            children: [
              TextSpan(
                text: '"${widget.item.name}"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '?'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if ((shouldDelete ?? false) && mounted) {
      setState(() => _isBusy = true);
      await widget.onDelete?.call();
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
      subtitle: _subtitle,
      trailing: IgnorePointer(
        ignoring: _isBusy,
        child: IconButton(
          key: widget.testKeys?.deleteButton,
          onPressed: (widget.onDelete != null) ? _onDeletePressed : null,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(),
          iconSize: isTablet ? 24 : 20,
          icon: const Icon(JPlayer.trash_2),
        ),
      ),
    );
  }
}
