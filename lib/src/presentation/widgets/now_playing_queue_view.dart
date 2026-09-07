import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/song_row_view.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';

class NowPlayingQueueView extends ConsumerStatefulWidget {
  const NowPlayingQueueView({this.padding = EdgeInsets.zero, super.key});

  final EdgeInsets padding;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealCurrentSong());
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

  void _revealCurrentSong() {
    if (!mounted || !_scrollController.hasClients) return;
    final index = ref.read(playbackProvider).currentMediaIndex ?? 0;
    _scrollController.jumpTo(
      (index * _itemExtent).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
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
            return SongRowView(
              key: keys[position],
              song: song,
              isPlaying: index == currentIndex,
              secondaryTextColor: Colors.white,
              edgePadding: 16,
              onTap: (_) => ref
                  .read(playbackProvider.notifier)
                  .skipTo(index, autoPlay: true),
              trailing: isShuffled
                  ? null
                  : ReorderableDragStartListener(
                      index: position,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.drag_handle,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
