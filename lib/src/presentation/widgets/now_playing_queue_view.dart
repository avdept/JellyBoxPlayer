import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/song_row_view.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const _dragBlur = 8.0;

class NowPlayingQueueView extends ConsumerStatefulWidget {
  const NowPlayingQueueView({
    this.padding = EdgeInsets.zero,
    this.isActive = true,
    super.key,
  });

  final EdgeInsets padding;

  final bool isActive;

  @override
  ConsumerState<NowPlayingQueueView> createState() =>
      _NowPlayingQueueViewState();
}

class _NowPlayingQueueViewState extends ConsumerState<NowPlayingQueueView> {
  final _scrollController = ScrollController();
  var _itemExtent = 62.0;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _revealCurrentSongOnNextFrame();
  }

  @override
  void didUpdateWidget(NowPlayingQueueView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _revealCurrentSongOnNextFrame();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _itemExtent =
        DeviceType.fromScreenSize(
          MediaQuery.sizeOf(context),
        ).isMobile
        ? 62.0
        : 72.0;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _revealCurrentSongOnNextFrame() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealCurrentSong());

  void _revealCurrentSong() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = ref.read(playbackProvider).currentMediaIndex ?? 0;
    final scroll = _scrollController.position;
    final centered =
        (position < 0 ? 0 : position) * _itemExtent -
        (scroll.viewportDimension - _itemExtent) / 2;

    _scrollController.jumpTo(centered.clamp(0.0, scroll.maxScrollExtent));
  }

  Future<void> _toggleFavourite(LibraryItem song) async {
    final favorite = !song.userData.isFavorite;
    if (ref.read(isOfflineProvider)) {
      _showOfflineNotice();
      return;
    }
    try {
      await ref
          .read(mediaServerClientProvider)
          .setFavorite(song.id, favorite: favorite);
    } on Object {
      _showOfflineNotice();
      return;
    }
    ref.invalidate(favouriteSongsProvider);
    ref
        .read(playbackProvider.notifier)
        .updateSong(
          song.copyWith(userData: song.userData.copyWith(isFavorite: favorite)),
        );
  }

  void _showOfflineNotice() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This action needs a connection')),
    );
  }

  List<Key> _itemKeys(List<LibraryItem> songs) {
    final seen = <String, int>{};
    return [
      for (final song in songs)
        ValueKey(
          '${song.id}#'
          '${seen.update(song.id, (count) => count + 1, ifAbsent: () => 0)}',
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider);
    final songs = playback.songs;
    final currentIndex = playback.currentMediaIndex;

    final keys = _itemKeys(songs);
    final isDesktop = DeviceType.fromScreenSize(
      MediaQuery.sizeOf(context),
    ).isDesktop;

    return ReorderableListView.builder(
      scrollController: _scrollController,
      padding: widget.padding,
      itemExtent: _itemExtent,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, dragged) {
          final lift = Curves.easeOut.transform(animation.value);
          return Transform.scale(
            scale: 1 + 0.04 * lift,
            child: lift < 0.01
                ? dragged
                : ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: _dragBlur * lift,
                        sigmaY: _dragBlur * lift,
                      ),
                      child: dragged,
                    ),
                  ),
          );
        },
        child: child,
      ),
      onReorder: (from, to) => ref
          .read(playbackProvider.notifier)
          .moveInQueue(from, to > from ? to - 1 : to),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return _QueueRow(
          key: keys[index],
          song: song,
          position: index,
          isPlaying: index == currentIndex,
          isDesktop: isDesktop,
          onTap: () =>
              ref.read(playbackProvider.notifier).skipTo(index, autoPlay: true),
          onLikePressed: () => _toggleFavourite(song),
          onRemove: () =>
              ref.read(playbackProvider.notifier).removeFromQueue(index),
        );
      },
    );
  }
}

class _QueueRow extends ConsumerStatefulWidget {
  const _QueueRow({
    required this.song,
    required this.position,
    required this.isPlaying,
    required this.isDesktop,
    required this.onTap,
    required this.onLikePressed,
    required this.onRemove,
    super.key,
  });

  final LibraryItem song;
  final int position;
  final bool isPlaying;
  final bool isDesktop;
  final VoidCallback onTap;
  final VoidCallback onLikePressed;
  final Future<void> Function() onRemove;

  @override
  ConsumerState<_QueueRow> createState() => _QueueRowState();
}

class _QueueRowState extends ConsumerState<_QueueRow> {
  @override
  Widget build(BuildContext context) {
    final row = SongRowView(
      song: widget.song,
      isPlaying: widget.isPlaying,
      secondaryTextColor: Colors.white,
      edgePadding: 16,
      onTap: (_) => widget.onTap(),
      onLikePressed: (_) => widget.onLikePressed(),
      trailing: widget.isDesktop ? null : _optionsButton(),
    );

    return GestureDetector(
      onSecondaryTapUp: (details) => showContextMenu(
        context,
        position: details.globalPosition,
        actions: _menuActions(context),
      ),
      child: widget.isDesktop
          ? ReorderableDragStartListener(
              index: widget.position,
              child: row,
            )
          : ReorderableDelayedDragStartListener(
              index: widget.position,
              child: row,
            ),
    );
  }

  List<ContextMenuAction> _menuActions(BuildContext context) => [
    ContextMenuAction(
      entry: ContextMenuEntry.removeFromQueue,
      icon: const Icon(Icons.remove_circle_outline),
      label: const Text('Remove from queue'),
      run: widget.onRemove,
    ),
    ...contextMenuActions(
      context,
      ref,
      widget.song,
      scope: ContextMenuScope.queue,
      onLike: (_) async => widget.onLikePressed(),
    ),
  ];

  Widget _optionsButton() => ContextMenuButton(actionsBuilder: _menuActions);
}
