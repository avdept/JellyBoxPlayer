import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/metadata_link_service.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/playlist_picker_sheet.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  metadataLinks,
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
          ContextMenuEntry.metadataLinks,
        ],
        ContextMenuScope.albumPage: [
          ContextMenuEntry.addToPlaylist,
          ContextMenuEntry.playNext,
          ContextMenuEntry.addToQueue,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
          ContextMenuEntry.metadataLinks,
        ],
        ContextMenuScope.playlistPage: [
          ContextMenuEntry.playNext,
          ContextMenuEntry.addToQueue,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
          ContextMenuEntry.goToAlbum,
          ContextMenuEntry.metadataLinks,
        ],
        ContextMenuScope.nowPlaying: [
          ContextMenuEntry.addToPlaylist,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
          ContextMenuEntry.goToAlbum,
          ContextMenuEntry.metadataLinks,
        ],
        ContextMenuScope.queue: [
          ContextMenuEntry.addToPlaylist,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
          ContextMenuEntry.goToAlbum,
          ContextMenuEntry.metadataLinks,
        ],
      },
      ItemKind.album: {
        ContextMenuScope.browse: [
          ContextMenuEntry.play,
          ContextMenuEntry.playNext,
          ContextMenuEntry.addToQueue,
          ContextMenuEntry.download,
          ContextMenuEntry.like,
          ContextMenuEntry.goToArtist,
          ContextMenuEntry.metadataLinks,
        ],
      },
      ItemKind.artist: {
        ContextMenuScope.browse: [
          ContextMenuEntry.play,
          ContextMenuEntry.like,
          ContextMenuEntry.metadataLinks,
        ],
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
    this.run,
    this.children = const [],
  });

  final ContextMenuEntry entry;
  final Widget icon;
  final Widget label;
  final Future<void> Function()? run;
  final List<ContextMenuAction> children;

  bool get isSubmenu => children.isNotEmpty;

  Widget get menuIcon =>
      Padding(padding: const EdgeInsetsDirectional.only(end: 4), child: icon);

  Widget toMenuItem(MenuController root) => isSubmenu
      ? _HoverSubmenu(action: this, root: root)
      : MenuItemButton(
          leadingIcon: menuIcon,
          onPressed: () {
            root.close();
            run?.call().ignore();
          },
          child: label,
        );

  ListTile toListTile(BuildContext context, {VoidCallback? onSelected}) =>
      ListTile(
        leading: icon,
        title: label,
        trailing: isSubmenu ? const Icon(Icons.chevron_right) : null,
        onTap: () {
          onSelected?.call();
          isSubmenu
              ? unawaited(showContextMenuSheet(context, actions: children))
              : run?.call().ignore();
        },
      );
}

class _HoverSubmenu extends StatefulWidget {
  const _HoverSubmenu({required this.action, required this.root});

  final ContextMenuAction action;
  final MenuController root;

  @override
  State<_HoverSubmenu> createState() => _HoverSubmenuState();
}

class _HoverSubmenuState extends State<_HoverSubmenu> {
  final _controller = MenuController();
  Timer? _closeTimer;
  var _openLeft = false;
  double _panelWidth = _menuMinWidth;

  void _handleHover(bool hovering) {
    _closeTimer?.cancel();
    if (hovering) return _measureSide();
    _closeTimer = Timer(_submenuCloseDelay, () {
      if (mounted && _controller.isOpen) _controller.close();
    });
  }

  void _measureSide() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final right = box.localToGlobal(Offset(box.size.width, 0)).dx;
    final openLeft = right + _panelWidth > MediaQuery.sizeOf(context).width;
    if (openLeft != _openLeft) setState(() => _openLeft = openLeft);
  }

  @override
  Widget build(BuildContext context) => SubmenuButton(
    controller: _controller,
    onHover: _handleHover,
    onOpen: _measureSide,
    leadingIcon: widget.action.menuIcon,
    trailingIcon: const Icon(Icons.arrow_right),
    menuStyle: _openLeft
        ? _submenuStyle.copyWith(alignment: AlignmentDirectional.topStart)
        : _submenuStyle,
    alignmentOffset: _openLeft ? Offset(-_panelWidth, 0) : null,
    menuChildren: [
      MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        child: _ReportWidth(
          onWidth: (width) {
            if (mounted && width != _panelWidth) {
              setState(() => _panelWidth = width);
            }
          },
          child: _MenuColumn(
            actions: widget.action.children,
            root: widget.root,
          ),
        ),
      ),
    ],
    child: widget.action.label,
  );
}

class _ReportWidth extends SingleChildRenderObjectWidget {
  const _ReportWidth({required this.onWidth, required super.child});

  final ValueChanged<double> onWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReportWidth(onWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderReportWidth renderObject,
  ) => renderObject.onWidth = onWidth;
}

class _RenderReportWidth extends RenderProxyBox {
  _RenderReportWidth(this.onWidth);

  ValueChanged<double> onWidth;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final width = size.width;
    if (width == _reported) return;
    _reported = width;
    WidgetsBinding.instance.addPostFrameCallback((_) => onWidth(width));
  }
}

class _MenuColumn extends StatelessWidget {
  const _MenuColumn({required this.actions, required this.root});

  final List<ContextMenuAction> actions;
  final MenuController root;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [for (final action in actions) action.toMenuItem(root)],
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
        ContextMenuEntry.metadataLinks => actions.metadataLinks(),
        ContextMenuEntry.removeFromQueue ||
        ContextMenuEntry.removeFromPlaylist ||
        ContextMenuEntry.deletePlaylist => null,
      },
  ].nonNulls.toList();
}

const _menuMinWidth = 224.0;
const _menuDuration = Duration(milliseconds: 150);
const _submenuCloseDelay = Duration(milliseconds: 250);
const _submenuStyle = MenuStyle(
  minimumSize: WidgetStatePropertyAll(Size(_menuMinWidth, 0)),
  alignment: AlignmentDirectional.topEnd,
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
);

void showContextMenu(
  BuildContext context, {
  required Offset position,
  required List<ContextMenuAction> actions,
}) {
  if (actions.isEmpty) return;
  final overlay = Navigator.of(context).overlay!;
  final overlayBox = overlay.context.findRenderObject()! as RenderBox;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned.fill(
      child: _AnimatedMenu(
        actions: actions,
        openAt: overlayBox.globalToLocal(position),
        onClosed: entry.remove,
        builder: (_, _, _) => const SizedBox.expand(),
      ),
    ),
  );
  overlay.insert(entry);
}

class _AnimatedMenu extends StatefulWidget {
  const _AnimatedMenu({
    required this.actions,
    required this.builder,
    this.openAt,
    this.onClosed,
  });

  final List<ContextMenuAction> actions;
  final RawMenuAnchorChildBuilder builder;
  final Offset? openAt;
  final VoidCallback? onClosed;

  @override
  State<_AnimatedMenu> createState() => _AnimatedMenuState();
}

class _AnimatedMenuState extends State<_AnimatedMenu>
    with SingleTickerProviderStateMixin {
  final _controller = MenuController();
  late final _animation = AnimationController(
    vsync: this,
    duration: _menuDuration,
  );
  late final _curve = CurvedAnimation(
    parent: _animation,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    if (widget.openAt case final position?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.open(position: position);
      });
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawMenuAnchor(
    controller: _controller,
    onOpenRequested: (_, showOverlay) {
      showOverlay();
      if (!_animation.status.isForwardOrCompleted) _animation.forward();
    },
    onCloseRequested: (hideOverlay) {
      if (!_animation.status.isForwardOrCompleted) return;
      unawaited(_animation.reverse().whenComplete(hideOverlay));
    },
    onClose: widget.onClosed,
    overlayBuilder: _buildPanel,
    builder: widget.builder,
  );

  Widget _buildPanel(BuildContext context, RawMenuOverlayInfo info) =>
      Positioned.fill(
        child: CustomSingleChildLayout(
          delegate: _MenuLayout(info.anchorRect, info.position),
          child: TapRegion(
            groupId: info.tapRegionGroupId,
            consumeOutsideTaps: true,
            onTapOutside: (_) => _controller.close(),
            child: FocusScope(
              autofocus: true,
              child: FadeTransition(
                opacity: _curve,
                child: ScaleTransition(
                  scale: _curve,
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 3,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(4),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicWidth(
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: _menuMinWidth,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _MenuColumn(
                          actions: widget.actions,
                          root: _controller,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _MenuLayout extends SingleChildLayoutDelegate {
  const _MenuLayout(this.anchorRect, this.position);

  final Rect anchorRect;
  final Offset? position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final origin = position == null
        ? anchorRect.bottomLeft
        : anchorRect.topLeft + position!;
    final flip = position == null ? anchorRect.topRight : origin;
    final x = origin.dx + childSize.width > size.width
        ? flip.dx - childSize.width
        : origin.dx;
    final y = origin.dy + childSize.height > size.height
        ? flip.dy - childSize.height
        : origin.dy;
    return Offset(
      x.clamp(0, math.max(0, size.width - childSize.width)),
      y.clamp(0, math.max(0, size.height - childSize.height)),
    );
  }

  @override
  bool shouldRelayout(_MenuLayout oldDelegate) =>
      anchorRect != oldDelegate.anchorRect || position != oldDelegate.position;
}

Future<void> showLongPressContextMenuSheet(
  BuildContext context, {
  required List<ContextMenuAction> actions,
}) {
  if (actions.isEmpty) return Future.value();
  HapticFeedback.mediumImpact().ignore();
  return showContextMenuSheet(context, actions: actions);
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
              context,
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
    return _AnimatedMenu(
      actions: actionsBuilder(context),
      builder: (context, controller, _) => IconButton(
        icon: Icon(icon),
        tooltip: 'More',
        style: style,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
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
    run: () => _enqueue(playNext: true),
  );

  ContextMenuAction addToQueue() => ContextMenuAction(
    entry: ContextMenuEntry.addToQueue,
    icon: const Icon(Icons.playlist_add),
    label: const Text('Add to queue'),
    run: () => _enqueue(playNext: false),
  );

  Future<void> _enqueue({required bool playNext}) async {
    final List<LibraryItem> songs;
    try {
      songs = await _queueableSongs();
    } on Object {
      _showSnackBar('Could not queue ${item.name}');
      return;
    }
    if (songs.isEmpty) {
      _showSnackBar('Nothing to queue in "${item.name}"');
      return;
    }
    final notifier = ref.read(playbackProvider.notifier);
    final set = item.kind == ItemKind.song ? null : item;
    final queued = playNext
        ? await notifier.playNextAll(songs, set: set)
        : await notifier.addAllToQueue(songs, set: set);
    if (!queued) {
      _showSnackBar('Could not queue ${item.name}');
    } else if (playNext) {
      _showSnackBar('Playing next');
    } else {
      _showSnackBar('Added to queue');
    }
  }

  Future<List<LibraryItem>> _queueableSongs() async {
    final playback = ref.read(setPlaybackProvider.notifier);
    return switch (item.kind) {
      ItemKind.song => [item],
      ItemKind.album => playback.albumSongs(item.id),
      ItemKind.playlist => playback.playlistSongs(item.id),
      _ => const [],
    };
  }

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

  ContextMenuAction? metadataLinks() {
    final links = metadataLinksFor(item.externalIds);
    if (links.isEmpty) return null;
    return ContextMenuAction(
      entry: ContextMenuEntry.metadataLinks,
      icon: const Icon(Icons.link),
      label: const Text('View on'),
      children: [
        for (final link in links)
          ContextMenuAction(
            entry: ContextMenuEntry.metadataLinks,
            icon: link.icon == null
                ? const Icon(Icons.open_in_new)
                : _SvgIcon(link.icon!),
            label: Text(link.label),
            run: () async {
              final opened = await launchUrl(
                link.uri,
                mode: LaunchMode.externalApplication,
              );
              if (!opened) _showSnackBar('Could not open ${link.label}');
            },
          ),
      ],
    );
  }
}

class _SvgIcon extends StatelessWidget {
  const _SvgIcon(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return SvgPicture.asset(
      asset,
      width: theme.size,
      height: theme.size,
      colorFilter: ColorFilter.mode(theme.color!, BlendMode.srcIn),
    );
  }
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
