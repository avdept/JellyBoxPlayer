import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/download_activity_provider.dart';
import 'package:jplayer/src/domain/providers/download_badge_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/presentation/utils/bold_name_span.dart';
import 'package:jplayer/src/presentation/widgets/adaptive_dialog_action.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';
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

  @override
  Widget build(BuildContext context) {
    final badge = ref.watch(downloadBadgeProvider((item.kind, item.id)));
    if (badge == null && ref.watch(isOfflineProvider)) {
      return const SizedBox.shrink();
    }
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    if (_preparing || badge == DownloadBadge.downloading) {
      return HoverIconButton(
        key: widget.testKeys?.delete,
        onPressed: _preparing ? null : _cancel,
        tooltip: S.of(context).stopDownload,
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
    return HoverIconButton(
      key: badge == null ? widget.testKeys?.download : widget.testKeys?.delete,
      onPressed: badge == null ? _download : _remove,
      tooltip: badge == null
          ? S.of(context).download
          : S.of(context).removeDownload,
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
        _notify(S.current.notAvailableOffline);
      }
      return;
    }
    if (list.isEmpty) {
      if (mounted) {
        setState(() => _preparing = false);
        _notify(S.current.nothingToDownload);
      }
      return;
    }
    final manager = ref.read(downloadManagerProvider);
    final download = _isAlbum
        ? manager.downloadAlbum(item, list)
        : manager.downloadPlaylist(item, list);
    if (mounted) setState(() => _preparing = false);
    await download;
  }

  Future<void> _cancel() => _delete();

  Future<void> _remove() async {
    final shouldDelete = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog.adaptive(
        key: widget.testKeys?.confirmationDialog,
        title: Text.rich(
          boldNameSpan(
            S.of(context).deleteDownloadedNameQuestion(item.name),
            item.name,
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
    if (!(shouldDelete ?? false) || !mounted) return;
    await _delete();
    if (mounted) {
      _notify(
        _isAlbum
            ? S.current.successfullyDeletedAlbum
            : S.current.successfullyDeletedPlaylist,
      );
    }
  }

  Future<void> _delete() {
    final manager = ref.read(downloadManagerProvider);
    return _isAlbum
        ? manager.deleteAlbum(item.id)
        : manager.deletePlaylist(item.id);
  }

  void _notify(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
