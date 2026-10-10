import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/presentation/pages/album/mobile/blurred_cover_art.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:just_audio/just_audio.dart';

class TvNowPlayingPage extends ConsumerWidget {
  const TvNowPlayingPage({super.key});

  static const _seekStep = Duration(seconds: 10);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(barMediaItemProvider);
    if (item == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nothing is playing', style: TvTokens.title),
              const SizedBox(height: 20),
              TvButton(
                label: 'Back',
                icon: Icons.arrow_back_rounded,
                autofocus: true,
                onSelect: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    final song = ref.watch(barSongProvider);
    final playing = ref.watch(barPlayingProvider);
    final progress = ref.watch(barProgressProvider);
    final shuffle = ref.watch(barShuffleProvider);
    final repeat = ref.watch(barRepeatProvider);
    final controls = ref.read(barControlsProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final art = ref
        .read(imageServiceProvider)
        .artworkImage(item.artUri, size: 800);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            BlurredCoverArt(
              image: art,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              background: Colors.black,
              blurStart: 0,
              sigma: 70,
            ),
            const ColoredBox(color: Color(0x99000000)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TvTokens.pagePaddingH + 16,
                vertical: TvTokens.pagePaddingV,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: TvTokens.panelRadius,
                          child: Image(
                            image: art,
                            width: 232,
                            height: 232,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            ?item.artist,
                            ?item.album,
                          ].join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SeekBar(
                          progress: progress,
                          accent: accent,
                          onSeek: (position) =>
                              unawaited(controls.seek(position)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              formatPlaybackTime(progress.position),
                              style: TvTokens.caption,
                            ),
                            const Spacer(),
                            Text(
                              formatPlaybackTime(progress.duration),
                              style: TvTokens.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            TvIconButton(
                              icon: Icons.shuffle_rounded,
                              selected: shuffle,
                              onSelect: () => unawaited(
                                controls.setShuffle(enabled: !shuffle),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TvIconButton(
                              icon: Icons.skip_previous_rounded,
                              iconSize: 28,
                              onSelect: () => unawaited(controls.previous()),
                            ),
                            const SizedBox(width: 12),
                            TvIconButton(
                              icon: playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 60,
                              iconSize: 34,
                              primary: true,
                              autofocus: true,
                              onSelect: () => unawaited(controls.togglePlay()),
                            ),
                            const SizedBox(width: 12),
                            TvIconButton(
                              icon: Icons.skip_next_rounded,
                              iconSize: 28,
                              onSelect: () => unawaited(controls.next()),
                            ),
                            const SizedBox(width: 12),
                            TvIconButton(
                              icon: repeat == LoopMode.one
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              selected: repeat != LoopMode.off,
                              onSelect: () => unawaited(
                                controls.setRepeat(_nextRepeat(repeat)),
                              ),
                            ),
                            if (song != null) ...[
                              const SizedBox(width: 12),
                              TvIconButton(
                                icon: song.userData.isFavorite
                                    ? CupertinoIcons.heart_fill
                                    : CupertinoIcons.heart,
                                iconSize: 22,
                                selected: song.userData.isFavorite,
                                onSelect: () =>
                                    unawaited(controls.toggleFavourite(song)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(flex: 8, child: _Queue(controls: controls)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static LoopMode _nextRepeat(LoopMode mode) => switch (mode) {
    LoopMode.off => LoopMode.all,
    LoopMode.all => LoopMode.one,
    LoopMode.one => LoopMode.off,
  };
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({
    required this.progress,
    required this.accent,
    required this.onSeek,
  });

  final BarProgress progress;
  final Color accent;
  final ValueChanged<Duration> onSeek;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  bool _focused = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final Duration delta;
    if (key == LogicalKeyboardKey.arrowRight) {
      delta = TvNowPlayingPage._seekStep;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      delta = -TvNowPlayingPage._seekStep;
    } else {
      return KeyEventResult.ignored;
    }
    final duration = widget.progress.duration;
    if (duration == Duration.zero) return KeyEventResult.handled;
    var target = widget.progress.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;
    widget.onSeek(target);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    final total = progress.duration.inMilliseconds;
    final fraction = total == 0
        ? 0.0
        : (progress.position.inMilliseconds / total).clamp(0.0, 1.0);
    final buffered = total == 0
        ? 0.0
        : (progress.buffered.inMilliseconds / total).clamp(0.0, 1.0);

    return Focus(
      onKeyEvent: _onKey,
      onFocusChange: (focused) => setState(() => _focused = focused),
      debugLabel: 'seek-bar',
      child: SizedBox(
        height: 24,
        child: Center(
          child: AnimatedContainer(
            duration: TvTokens.focusDuration,
            height: _focused ? 10 : 5,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(5),
              boxShadow: _focused ? TvTokens.glow(alpha: 0.25) : const [],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: buffered,
                  child: const ColoredBox(color: Colors.white24),
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: ColoredBox(
                    color: _focused ? Colors.white : widget.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Queue extends ConsumerStatefulWidget {
  const _Queue({required this.controls});

  final BarControls controls;

  @override
  ConsumerState<_Queue> createState() => _QueueState();
}

class _QueueState extends ConsumerState<_Queue> {
  static const _rowHeight = 58.0;

  final _scroll = ScrollController();
  int? _shownIndex;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _revealCurrent(int index, int length) {
    if (_shownIndex == index) return;
    _shownIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final focus = FocusManager.instance.primaryFocus;
      final browsing =
          focus != null &&
          focus.context != null &&
          focus.context!.findAncestorStateOfType<_QueueState>() == this;
      if (browsing) return;
      final target = ((index - 2) * _rowHeight).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(barQueueProvider);
    final index = ref.watch(barQueueIndexProvider) ?? -1;
    if (index >= 0) _revealCurrent(index, queue.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Queue · ${queue.length} ${queue.length == 1 ? 'song' : 'songs'}',
            style: TvTokens.sectionTitle,
          ),
        ),
        Expanded(
          child: queue.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('The queue is empty', style: TvTokens.caption),
                )
              : FocusTraversalGroup(
                  child: ListView.builder(
                    controller: _scroll,
                    itemExtent: _rowHeight,
                    itemCount: queue.length,
                    itemBuilder: (context, position) => TvSongRow(
                      song: queue[position],
                      position: position + 1,
                      isPlaying: position == index,
                      onSelect: () =>
                          unawaited(widget.controls.skipTo(position)),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
