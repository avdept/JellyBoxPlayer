import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/song_download_menu_item.dart';
import 'package:jplayer/src/presentation/widgets/song_row_view.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';

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
    final currentIndex = ref.read(playbackProvider).currentMediaIndex ?? 0;
    final order = _order(
      ref.read(playerProvider).sequenceState,
      ref.read(playbackProvider).songs.length,
    );
    final position = order.indexOf(currentIndex);
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

  List<Key> _itemKeys(List<int> order, List<LibraryItem> songs) {
    final seen = <String, int>{};
    return [
      for (final index in order)
        ValueKey(
          '${songs[index].id}#'
          '${seen.update(songs[index].id, (count) => count + 1, ifAbsent: () => 0)}',
        ),
    ];
  }

  List<int> _order(SequenceState? state, int length) {
    if (state == null ||
        !state.shuffleModeEnabled ||
        state.shuffleIndices.length != length) {
      return List.generate(length, (index) => index);
    }
    return state.shuffleIndices;
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider);
    final songs = playback.songs;
    final currentIndex = playback.currentMediaIndex;

    return StreamBuilder<SequenceState?>(
      stream: ref.read(playerProvider).sequenceStateStream,
      builder: (context, snapshot) {
        final isShuffled = snapshot.data?.shuffleModeEnabled ?? false;
        final order = _order(snapshot.data, songs.length);
        final keys = _itemKeys(order, songs);
        final isDesktop = DeviceType.fromScreenSize(
          MediaQuery.sizeOf(context),
        ).isDesktop;
        return ReorderableListView.builder(
          scrollController: _scrollController,
          padding: widget.padding,
          itemExtent: _itemExtent,
          buildDefaultDragHandles: false,
          onReorder: (from, to) => ref
              .read(playbackProvider.notifier)
              .moveInQueue(from, to > from ? to - 1 : to),
          itemCount: order.length,
          itemBuilder: (context, position) {
            final index = order[position];
            final song = songs[index];
            return _QueueRow(
              key: keys[position],
              song: song,
              position: position,
              isPlaying: index == currentIndex,
              isDesktop: isDesktop,
              isDraggable: !isShuffled,
              onTap: () => ref
                  .read(playbackProvider.notifier)
                  .skipTo(index, autoPlay: true),
              onLikePressed: () => _toggleFavourite(song),
              onRemove: () =>
                  ref.read(playbackProvider.notifier).removeFromQueue(index),
            );
          },
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
    required this.isDraggable,
    required this.onTap,
    required this.onLikePressed,
    required this.onRemove,
    super.key,
  });

  final LibraryItem song;
  final int position;
  final bool isPlaying;
  final bool isDesktop;
  final bool isDraggable;
  final VoidCallback onTap;
  final VoidCallback onLikePressed;
  final Future<void> Function() onRemove;

  @override
  ConsumerState<_QueueRow> createState() => _QueueRowState();
}

class _QueueRowState extends ConsumerState<_QueueRow> {
  var _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final row = SongRowView(
      song: widget.song,
      isPlaying: widget.isPlaying,
      secondaryTextColor: Colors.white,
      edgePadding: 16,
      onTap: (_) => widget.onTap(),
      onLikePressed: (_) => widget.onLikePressed(),
      trailing: _optionsButton(),
    );

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: switch ((widget.isDraggable, widget.isDesktop)) {
        (false, _) => row,
        (true, true) => ReorderableDragStartListener(
          index: widget.position,
          child: row,
        ),
        (true, false) => ReorderableDelayedDragStartListener(
          index: widget.position,
          child: row,
        ),
      },
    );
  }

  Widget _optionsButton() => AnimatedOpacity(
    opacity: (_isHovered || !widget.isDesktop) ? 1 : 0,
    duration: const Duration(milliseconds: 120),
    child: PopupMenuButton<void>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'More',
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () => widget.onRemove().ignore(),
          child: const Text('Remove from queue'),
        ),
        songDownloadMenuItem(ref, widget.song),
      ],
    ),
  );
}
