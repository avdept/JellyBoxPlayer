import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/download_badge_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/presentation/widgets/adaptive_dialog_action.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class CollectionDownloadButtonKeys {
  const CollectionDownloadButtonKeys({
    required this.download,
    required this.delete,
    required this.confirmationDialog,
  });

  final Key download;
  final Key delete;
  final Key confirmationDialog;
}

class CollectionDownloadButton extends ConsumerStatefulWidget {
  const CollectionDownloadButton({
    required this.item,
    required this.songs,
    this.testKeys,
    super.key,
  });

  final LibraryItem item;
  final Future<List<LibraryItem>> Function() songs;
  final CollectionDownloadButtonKeys? testKeys;

  @override
  ConsumerState<CollectionDownloadButton> createState() =>
      _CollectionDownloadButtonState();
}

class _CollectionDownloadButtonState
    extends ConsumerState<CollectionDownloadButton> {
  var _preparing = false;

  LibraryItem get item => widget.item;

  bool get _isAlbum => item.kind == ItemKind.album;

  String get _noun => _isAlbum ? 'album' : 'playlist';

  @override
  Widget build(BuildContext context) {
    final badge = ref.watch(downloadBadgeProvider((item.kind, item.id)));
    if (badge == null && ref.watch(isOfflineProvider)) {
      return const SizedBox.shrink();
    }
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    if (_preparing || badge == DownloadBadge.downloading) {
      return IconButton(
        key: widget.testKeys?.delete,
        onPressed: _preparing ? null : _cancel,
        tooltip: 'Stop download',
        icon: SizedBox.square(
          dimension: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _preparing
                    ? null
                    : ref.watch(downloadProgressProvider(item.id)),
                strokeWidth: 2,
                backgroundColor: onPrimary.withValues(alpha: 0.24),
              ),
              Icon(JPlayer.trash_2, size: 12, color: onPrimary),
            ],
          ),
        ),
      );
    }
    return IconButton(
      key: badge == null ? widget.testKeys?.download : widget.testKeys?.delete,
      onPressed: badge == null ? _download : _remove,
      tooltip: badge == null ? 'Download' : 'Remove download',
      icon: Icon(badge == null ? JPlayer.download : JPlayer.trash_2),
    );
  }

  Future<void> _download() async {
    setState(() => _preparing = true);
    final List<LibraryItem> list;
    try {
      list = await widget.songs();
    } on Object {
      if (mounted) {
        setState(() => _preparing = false);
        _notify('Not available offline');
      }
      return;
    }
    if (list.isEmpty) {
      if (mounted) {
        setState(() => _preparing = false);
        _notify('Nothing to download');
      }
      return;
    }
    final manager = ref.read(downloadManagerProvider.notifier);
    final download = _isAlbum
        ? manager.downloadAlbum(item, list)
        : manager.downloadPlaylist(item, list);
    if (mounted) setState(() => _preparing = false);
    await download;
  }

  Future<void> _cancel() => _delete();

  Future<void> _remove() async {
    final shouldDelete = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        key: widget.testKeys?.confirmationDialog,
        title: Text.rich(
          TextSpan(
            text: 'Delete downloaded ',
            children: [
              TextSpan(
                text: '"${item.name}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
    if (!(shouldDelete ?? false) || !mounted) return;
    await _delete();
    if (mounted) _notify('Successfully deleted $_noun');
  }

  Future<void> _delete() {
    final manager = ref.read(downloadManagerProvider.notifier);
    return _isAlbum
        ? manager.deleteAlbum(item.id)
        : manager.deletePlaylist(item.id);
  }

  void _notify(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
