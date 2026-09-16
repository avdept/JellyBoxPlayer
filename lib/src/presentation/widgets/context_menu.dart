import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/playlist_picker_sheet.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const contextMenuAnimation = AnimationStyle(
  duration: Duration(milliseconds: 150),
);

enum ContextMenuScope { browse, albumPage, playlistPage, nowPlaying, queue }

enum ContextMenuEntry {
  play,
  addToPlaylist,
  playNext,
  addToQueue,
  download,
  like,
  goToArtist,
  goToAlbum,
  removeFromQueue,
  removeFromPlaylist,
  deletePlaylist,
}

const contextMenuLayout =
    <ItemKind, Map<ContextMenuScope, List<ContextMenuEntry>>>{
      ItemKind.song: {
        ContextMenuScope.browse: [
          ContextMenuEntry.addToPlaylist,
          ContextMenuEntry.playNext,
          ContextMenuEntry.addToQueue,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
          ContextMenuEntry.goToAlbum,
        ],
        ContextMenuScope.albumPage: [
          ContextMenuEntry.addToPlaylist,
          ContextMenuEntry.playNext,
          ContextMenuEntry.addToQueue,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
        ],
        ContextMenuScope.playlistPage: [
          ContextMenuEntry.playNext,
          ContextMenuEntry.addToQueue,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
          ContextMenuEntry.goToAlbum,
        ],
        ContextMenuScope.nowPlaying: [
          ContextMenuEntry.addToPlaylist,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
          ContextMenuEntry.goToAlbum,
        ],
        ContextMenuScope.queue: [
          ContextMenuEntry.addToPlaylist,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
          ContextMenuEntry.goToAlbum,
        ],
      },
      ItemKind.album: {
        ContextMenuScope.browse: [
          ContextMenuEntry.play,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
        ],
      },
      ItemKind.artist: {
        ContextMenuScope.browse: [ContextMenuEntry.play, ContextMenuEntry.like],
      },
      ItemKind.playlist: {
        ContextMenuScope.browse: [
          ContextMenuEntry.play,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
        ],
      },
      ItemKind.genre: {
        ContextMenuScope.browse: [ContextMenuEntry.play],
      },
    };

List<ContextMenuEntry> contextMenuEntries(
  LibraryItem item,
  ContextMenuScope scope,
) => contextMenuLayout[item.kind]?[scope] ?? const [];

class ContextMenuAction {
  const ContextMenuAction({
    required this.entry,
    required this.icon,
    required this.label,
    required this.run,
  });

  final ContextMenuEntry entry;
  final Widget icon;
  final Widget label;
  final Future<void> Function() run;

  PopupMenuItem<void> toPopupMenuItem() =>
      PopupMenuItem(onTap: () => run().ignore(), child: label);

  ListTile toListTile({VoidCallback? onSelected}) => ListTile(
    leading: icon,
    title: label,
    onTap: () {
      onSelected?.call();
      run().ignore();
    },
  );
}

bool hasContextMenu(LibraryItem item, ContextMenuScope scope) =>
    contextMenuEntries(item, scope).isNotEmpty;

List<ContextMenuAction> contextMenuActions(
  BuildContext context,
  WidgetRef ref,
  LibraryItem item, {
  required ContextMenuScope scope,
  Future<void> Function(LibraryItem item)? onLike,
}) {
  final isDesktop = DeviceType.fromScreenSize(
    MediaQuery.sizeOf(context),
  ).isDesktop;
  final rowHasLike = isDesktop && item.kind == ItemKind.song;
  final actions = _ContextMenuActions(context, ref, item, scope);

  return [
    for (final entry in contextMenuEntries(item, scope))
      switch (entry) {
        ContextMenuEntry.play => actions.play(),
        ContextMenuEntry.addToPlaylist => actions.addToPlaylist(),
        ContextMenuEntry.playNext => actions.playNext(),
        ContextMenuEntry.addToQueue => actions.addToQueue(),
        ContextMenuEntry.download => actions.download(),
        ContextMenuEntry.like =>
          onLike != null && !rowHasLike ? actions.like(onLike) : null,
        ContextMenuEntry.goToArtist =>
          item.effectiveArtists.isNotEmpty ? actions.goToArtist() : null,
        ContextMenuEntry.goToAlbum =>
          item.albumId != null ? actions.goToAlbum() : null,
        ContextMenuEntry.removeFromQueue ||
        ContextMenuEntry.removeFromPlaylist ||
        ContextMenuEntry.deletePlaylist => null,
      },
  ].nonNulls.toList();
}

Future<void> showContextMenu(
  BuildContext context, {
  required Offset position,
  required List<ContextMenuAction> actions,
}) async {
  if (actions.isEmpty) return;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final local = overlay.globalToLocal(position);
  await showMenu<void>(
    context: context,
    popUpAnimationStyle: contextMenuAnimation,
    constraints: const BoxConstraints(minWidth: 224),
    position: RelativeRect.fromRect(
      Rect.fromPoints(local, local),
      Offset.zero & overlay.size,
    ),
    items: [for (final action in actions) action.toPopupMenuItem()],
  );
}

Future<void> showContextMenuSheet(
  BuildContext context, {
  required List<ContextMenuAction> actions,
}) async {
  if (actions.isEmpty) return;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in actions)
            action.toListTile(
              onSelected: () => Navigator.of(sheetContext).pop(),
            ),
        ],
      ),
    ),
  );
}

class ContextMenuButton extends StatelessWidget {
  const ContextMenuButton({
    required this.actionsBuilder,
    this.icon = Icons.more_vert,
    this.style,
    super.key,
  });

  final List<ContextMenuAction> Function(BuildContext context) actionsBuilder;
  final IconData icon;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceType.fromScreenSize(
      MediaQuery.sizeOf(context),
    ).isDesktop;
    if (!isDesktop) {
      return IconButton(
        icon: Icon(icon),
        tooltip: 'More',
        style: style,
        onPressed: () =>
            showContextMenuSheet(context, actions: actionsBuilder(context)),
      );
    }
    return PopupMenuButton<void>(
      popUpAnimationStyle: contextMenuAnimation,
      icon: Icon(icon),
      tooltip: 'More',
      style: style,
      itemBuilder: (context) => [
        for (final action in actionsBuilder(context)) action.toPopupMenuItem(),
      ],
    );
  }
}

class _ContextMenuActions {
  const _ContextMenuActions(this.context, this.ref, this.item, this.scope);

  final BuildContext context;
  final WidgetRef ref;
  final LibraryItem item;
  final ContextMenuScope scope;

  bool get _mounted => context.mounted;

  bool get _insidePlayer =>
      scope == ContextMenuScope.nowPlaying || scope == ContextMenuScope.queue;

  bool get _isDesktop =>
      DeviceType.fromScreenSize(MediaQuery.sizeOf(context)).isDesktop;

  void _showSnackBar(String message) {
    if (!_mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _guardOffline() {
    if (!ref.read(isOfflineProvider)) return false;
    _showSnackBar('Not available offline');
    return true;
  }

  void _navigate(Routes route, String key, LibraryItem target) {
    if (!_mounted) return;
    final extra = {key: target};
    if (_insidePlayer) {
      final router = GoRouter.of(context);
      if (!_isDesktop) Navigator.of(context).pop();
      router.goNamed(route.name, extra: extra);
    } else {
      unawaited(
        context.pushNamed(branchAwareName(context, route), extra: extra),
      );
    }
  }

  ContextMenuAction play() => ContextMenuAction(
    entry: ContextMenuEntry.play,
    icon: const Icon(Icons.play_arrow),
    label: Text(switch (item.kind) {
      ItemKind.album => 'Play album',
      ItemKind.artist => 'Play artist',
      ItemKind.playlist => 'Play playlist',
      ItemKind.genre => 'Play genre',
      _ => 'Play',
    }),
    run: () async {
      final notifier = ref.read(setPlaybackProvider.notifier);
      try {
        final result = await switch (item.kind) {
          ItemKind.album => notifier.playAlbum(item),
          ItemKind.artist => notifier.playArtist(item),
          ItemKind.genre => notifier.playGenre(item),
          ItemKind.playlist => notifier.playPlaylist(item),
          _ => Future.value(SetPlaybackResult.busy),
        };
        if (result == SetPlaybackResult.empty) {
          _showSnackBar('Nothing to play in "${item.name}"');
        }
      } on Object {
        _showSnackBar('Could not start playing "${item.name}"');
      }
    },
  );

  ContextMenuAction addToPlaylist() => ContextMenuAction(
    entry: ContextMenuEntry.addToPlaylist,
    icon: const Icon(CupertinoIcons.text_badge_plus),
    label: const Text('Add to playlist'),
    run: () async {
      if (_guardOffline()) return;
      final playlist = await showPlaylistPicker(
        context,
        isDesktop: _isDesktop,
      );
      if (playlist == null || !_mounted) return;
      await ref
          .read(mediaServerClientProvider)
          .addPlaylistItems(playlistId: playlist.id, itemIds: [item.id]);
      _showSnackBar('Successfully added to playlist');
    },
  );

  ContextMenuAction playNext() => ContextMenuAction(
    entry: ContextMenuEntry.playNext,
    icon: const Icon(Icons.playlist_play),
    label: const Text('Play next'),
    run: () async {
      final queued = await ref.read(playbackProvider.notifier).playNext(item);
      _showSnackBar(queued ? 'Playing next' : 'Could not queue ${item.name}');
    },
  );

  ContextMenuAction addToQueue() => ContextMenuAction(
    entry: ContextMenuEntry.addToQueue,
    icon: const Icon(Icons.playlist_add),
    label: const Text('Add to queue'),
    run: () async {
      final queued = await ref.read(playbackProvider.notifier).addToQueue(item);
      _showSnackBar(
        queued ? 'Added to queue' : 'Could not queue ${item.name}',
      );
    },
  );

  ContextMenuAction download() => ContextMenuAction(
    entry: ContextMenuEntry.download,
    icon: _DownloadState(item: item, builder: _downloadIcon),
    label: _DownloadState(item: item, builder: _downloadLabel),
    run: () async {
      final manager = ref.read(downloadManagerProvider.notifier);
      final client = ref.read(mediaServerClientProvider);
      switch (item.kind) {
        case ItemKind.song:
          if (await manager.isSongDownloaded(item.id)) {
            await manager.deleteSong(item.id);
          } else {
            await manager.downloadSong(item);
          }
        case ItemKind.album:
          if (await manager.isAlbumDownloaded(item.id)) {
            await manager.deleteAlbum(item.id);
          } else {
            if (_guardOffline()) return;
            final page = await client.getSongs(item.id);
            await manager.downloadAlbum(item, page.items);
          }
        case ItemKind.playlist:
          if (await manager.isPlaylistDownloaded(item.id)) {
            await manager.deletePlaylist(item.id);
          } else {
            if (_guardOffline()) return;
            final page = await client.getPlaylistSongs(item.id);
            await manager.downloadPlaylist(item, page.items);
          }
        case _:
          return;
      }
    },
  );

  static Widget _downloadIcon(bool isDownloaded) =>
      Icon(isDownloaded ? Icons.delete_outline : JPlayer.download);

  static Widget _downloadLabel(bool isDownloaded) =>
      Text(isDownloaded ? 'Remove download' : 'Download');

  ContextMenuAction like(Future<void> Function(LibraryItem item) onLike) {
    final isFavorite = item.userData.isFavorite;
    return ContextMenuAction(
      entry: ContextMenuEntry.like,
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      label: Text(
        isFavorite ? 'Remove from favourites' : 'Add to favourites',
      ),
      run: () async {
        if (_guardOffline()) return;
        await onLike(item);
      },
    );
  }

  ContextMenuAction goToArtist() => ContextMenuAction(
    entry: ContextMenuEntry.goToArtist,
    icon: const Icon(CupertinoIcons.person),
    label: const Text('Go to artist'),
    run: () async {
      final artistId = item.effectiveArtists.first.id;
      final target = await ref
          .read(mediaServerClientProvider)
          .getItem(artistId, kind: ItemKind.artist);
      _navigate(Routes.artist, 'artist', target);
    },
  );

  ContextMenuAction goToAlbum() => ContextMenuAction(
    entry: ContextMenuEntry.goToAlbum,
    icon: const Icon(Icons.album_outlined),
    label: const Text('Go to album'),
    run: () async {
      final target = await ref
          .read(mediaServerClientProvider)
          .getItem(item.albumId!, kind: ItemKind.album);
      if (!_mounted) return;
      ref.read(currentAlbumProvider.notifier).setAlbum(target);
      _navigate(Routes.album, 'album', target);
    },
  );
}

class _DownloadState extends ConsumerWidget {
  const _DownloadState({required this.item, required this.builder});

  final LibraryItem item;
  final Widget Function(bool isDownloaded) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = switch (item.kind) {
      ItemKind.album => isAlbumDownloadedProvider(item),
      ItemKind.playlist => isPlaylistDownloadedProvider(item),
      _ => isSongDownloadedProvider(item),
    };
    return builder(ref.watch(provider).valueOrNull ?? false);
  }
}
