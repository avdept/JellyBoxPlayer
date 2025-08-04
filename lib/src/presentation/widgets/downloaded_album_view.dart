import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
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

class DownloadedAlbumView extends ConsumerStatefulWidget {
  const DownloadedAlbumView({
    required this.album,
    this.onTap,
    this.onDelete,
    @visibleForTesting this.testKeys,
    super.key,
  });

  final DownloadedAlbumDTO album;
  final void Function(DownloadedAlbumDTO)? onTap;
  final FutureOr<void> Function(DownloadedAlbumDTO)? onDelete;
  final DownloadedAlbumViewKeys? testKeys;

  @override
  ConsumerState<DownloadedAlbumView> createState() =>
      _DownloadedAlbumViewState();
}

class _DownloadedAlbumViewState extends ConsumerState<DownloadedAlbumView> {
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
                text: '"${widget.album.name}"',
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
      await widget.onDelete?.call(widget.album);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isDesktop = deviceType == DeviceScreenType.desktop;
    final imageProvider = (widget.album.imageTags['Primary'] == null)
        ? const AssetImage(Images.albumSample)
        : NetworkImage(
            ref
                .read(imageServiceProvider)
                .imagePath(
                  tagId: widget.album.imageTags['Primary']!,
                  id: widget.album.id,
                ),
          );

    return GestureDetector(
      onTap: (widget.onTap != null)
          ? () => widget.onTap!.call(widget.album)
          : null,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Offstage(
              offstage: !isDesktop,
              child: AspectRatio(
                aspectRatio: 1,
                child: Image(
                  image: imageProvider as ImageProvider<Object>,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            SimpleListTile(
              leading: Offstage(
                offstage: isDesktop,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),
              ),
              title: Text(
                widget.album.name,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  color: theme.colorScheme.onPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
              subtitle: Text(
                _formatSize(widget.album.sizeInBytes),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  color: theme.colorScheme.onPrimary.withOpacity(0.61),
                ),
              ),
              trailing: IgnorePointer(
                ignoring: _isBusy,
                child: IconButton(
                  key: widget.testKeys?.deleteButton,
                  onPressed: (widget.onDelete != null)
                      ? _onDeletePressed
                      : null,
                  padding: EdgeInsets.zero,
                  icon: const Icon(JPlayer.trash_2),
                ),
              ),
              leadingToTitle: isDesktop ? 0 : (isMobile ? 6 : 16),
            ),
          ],
        ),
      ),
    );
  }
}
