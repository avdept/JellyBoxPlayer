import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/audio_quality_badge.dart';
import 'package:jplayer/src/presentation/widgets/lyrics_overlay.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class TvNowPlayingPage extends ConsumerStatefulWidget {
  const TvNowPlayingPage({super.key});

  static const _seekStep = Duration(seconds: 10);

  @override
  ConsumerState<TvNowPlayingPage> createState() => _TvNowPlayingPageState();
}

class _TvNowPlayingPageState extends ConsumerState<TvNowPlayingPage> {
  static const _queueWidth = 400.0;
  static const _slide = Duration(milliseconds: 250);
  static const double _contentPadding = TvTokens.pagePaddingH + 16;

  final _queueButton = FocusNode(debugLabel: 'now-playing:queue');
  bool _queueOpen = false;
  bool _queueBuilt = false;

  @override
  void dispose() {
    _queueButton.dispose();
    super.dispose();
  }

  void _openQueue() => setState(() {
    _queueOpen = true;
    _queueBuilt = true;
  });

  void _toggleLyrics() {
    final lyrics = ref.read(lyricsVisibleProvider.notifier);
    lyrics.state = !lyrics.state;
    final settings = ref.read(appSettingsProvider.notifier);
    if (settings.isEnabled(AppSetting.tvRememberLyrics)) {
      settings.setEnabled(AppSetting.tvLyricsShown, value: lyrics.state);
    }
  }

  void _closeQueue() {
    setState(() => _queueOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _queueButton.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
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

    final controls = ref.read(barControlsProvider);
    final images = ref.read(imageServiceProvider);
    final art = images.artworkImage(item.artUri, size: 512);
    final backdrop = images.artworkImage(item.artUri, size: 128);
    final lyricsOn = ref.watch(lyricsVisibleProvider);
    final rememberLyrics = ref.watch(
      settingProvider(AppSetting.tvRememberLyrics),
    );

    return PopScope(
      canPop: !_queueOpen && (!lyricsOn || rememberLyrics),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_queueOpen) {
          _closeQueue();
        } else {
          _toggleLyrics();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            TvBackdrop(image: backdrop),
            ExcludeFocus(
              excluding: _queueOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _contentPadding,
                      TvTokens.pagePaddingV,
                      _contentPadding,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TvIconButton(
                          icon: lyricsOn
                              ? Icons.lyrics_rounded
                              : Icons.lyrics_outlined,
                          size: _Player.buttonSize,
                          iconSize: _Player.iconSize,
                          selected: lyricsOn,
                          onSelect: _toggleLyrics,
                        ),
                        const SizedBox(width: 12),
                        TvIconButton(
                          icon: Icons.format_list_bulleted_rounded,
                          size: _Player.buttonSize,
                          iconSize: _Player.iconSize,
                          focusNode: _queueButton,
                          onSelect: _openQueue,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Player(
                            item: item,
                            art: art,
                            controls: controls,
                            split: lyricsOn,
                          ),
                        ),
                        if (lyricsOn)
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                0,
                                0,
                                _contentPadding,
                                TvTokens.pagePaddingV,
                              ),
                              child: LyricsView(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(end: _queueOpen ? 1 : 0),
              duration: _slide,
              curve: Curves.easeOutCubic,
              builder: (context, value, panel) => Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.54 * value),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: -_queueWidth * (1 - value),
                    width: _queueWidth,
                    child: _queueBuilt
                        ? Visibility(
                            visible: value > 0,
                            maintainState: true,
                            child: panel!,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              child: ExcludeFocus(
                excluding: !_queueOpen,
                child: FocusScope(
                  child: _Queue(controls: controls, open: _queueOpen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Player extends ConsumerWidget {
  const _Player({
    required this.item,
    required this.art,
    required this.controls,
    required this.split,
  });

  final MediaItem item;
  final ImageProvider art;
  final BarControls controls;
  final bool split;

  static const buttonSize = 36.0;
  static const iconSize = 18.0;
  static const double _button = buttonSize;
  static const double _icon = iconSize;
  static final TextStyle _timeStyle = TvTokens.caption.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(barSongProvider);
    final playing = ref.watch(barPlayingProvider);
    final progress = ref.watch(barProgressProvider);
    final shuffle = ref.watch(barShuffleProvider);
    final repeat = ref.watch(barRepeatProvider);
    final elsewhere = ref.watch(remoteRendererProvider);
    final accent = Theme.of(context).colorScheme.primary;

    final coverSize = split ? 170.0 : 220.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _TvNowPlayingPageState._contentPadding,
        0,
        _TvNowPlayingPageState._contentPadding,
        TvTokens.pagePaddingV,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: TvTokens.panelRadius,
                  child: Image(
                    image: art,
                    width: coverSize,
                    height: coverSize,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: split ? 22 : 28,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [?item.artist, ?item.album].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                      if (elsewhere != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.cast_connected_rounded,
                              size: 16,
                              color: accent,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Playing on ${elsewhere.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SeekBar(
            progress: progress,
            accent: accent,
            onSeek: (position) => unawaited(controls.seek(position)),
          ),
          const SizedBox(height: 6),
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Text(
                    formatPlaybackTime(progress.position),
                    style: _timeStyle,
                  ),
                  const Spacer(),
                  Text(
                    formatPlaybackTime(progress.duration),
                    style: _timeStyle,
                  ),
                ],
              ),
              AudioQualityBadge.heard(item.extras, textColor: Colors.white70),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (song != null)
                TvIconButton(
                  icon: song.userData.isFavorite
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  size: _button,
                  iconSize: _icon,
                  selected: song.userData.isFavorite,
                  onSelect: () => unawaited(controls.toggleFavourite(song)),
                )
              else
                const SizedBox.square(dimension: _button),
              const Spacer(),
              TvIconButton(
                icon: Icons.shuffle_rounded,
                size: _button,
                iconSize: _icon,
                selected: shuffle,
                onSelect: () =>
                    unawaited(controls.setShuffle(enabled: !shuffle)),
              ),
              const SizedBox(width: 16),
              TvIconButton(
                icon: Icons.skip_previous_rounded,
                size: _button,
                iconSize: 22,
                onSelect: () => unawaited(controls.previous()),
              ),
              const SizedBox(width: 16),
              TvIconButton(
                icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 48,
                iconSize: 26,
                primary: true,
                autofocus: true,
                onSelect: () => unawaited(controls.togglePlay()),
              ),
              const SizedBox(width: 16),
              TvIconButton(
                icon: Icons.skip_next_rounded,
                size: _button,
                iconSize: 22,
                onSelect: () => unawaited(controls.next()),
              ),
              const SizedBox(width: 16),
              TvIconButton(
                icon: repeat == LoopMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                size: _button,
                iconSize: _icon,
                selected: repeat != LoopMode.off,
                onSelect: () =>
                    unawaited(controls.setRepeat(_nextRepeat(repeat))),
              ),
              const Spacer(),
              TvIconButton(
                icon: elsewhere == null
                    ? Icons.cast_rounded
                    : Icons.cast_connected_rounded,
                size: _button,
                iconSize: _icon,
                selected: elsewhere != null,
                onSelect: () => unawaited(TvPlayOnDialog.show(context)),
              ),
            ],
          ),
        ],
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
            width: double.infinity,
            height: _focused ? 10 : 5,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(5),
              boxShadow: _focused ? TvTokens.glow(alpha: 0.25) : const [],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: buffered,
                  child: const ColoredBox(color: Colors.white24),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
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
  const _Queue({required this.controls, required this.open});

  final BarControls controls;
  final bool open;

  @override
  ConsumerState<_Queue> createState() => _QueueState();
}

class _QueueState extends ConsumerState<_Queue> {
  static const _rowHeight = 72.0;

  final _scroll = ScrollController();
  final _currentRow = FocusNode(debugLabel: 'queue:current');
  int? _shownIndex;

  @override
  void initState() {
    super.initState();
    if (widget.open) _focusCurrent();
  }

  @override
  void didUpdateWidget(_Queue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open && !oldWidget.open) _focusCurrent();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _currentRow.dispose();
    super.dispose();
  }

  double _offsetFor(int index) =>
      ((index - 2) * _rowHeight).clamp(0.0, _scroll.position.maxScrollExtent);

  void _focusCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final index = ref.read(barQueueIndexProvider) ?? -1;
      if (index >= 0) _scroll.jumpTo(_offsetFor(index));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_currentRow.context != null) {
          _currentRow.requestFocus();
        } else {
          FocusScope.of(
            context,
          ).traversalDescendants.firstOrNull?.requestFocus();
        }
      });
    });
  }

  void _revealCurrent(int index) {
    if (_shownIndex == index) return;
    _shownIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (widget.open) return;
      _scroll.jumpTo(_offsetFor(index));
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(barQueueProvider);
    final index = ref.watch(barQueueIndexProvider) ?? -1;
    if (index >= 0) _revealCurrent(index);

    final theme = Theme.of(context);
    final tint = (theme.bottomSheetTheme.backgroundColor ?? Colors.black)
        .withValues(alpha: 0.88);

    return Material(
      color: tint,
      elevation: 12,
      surfaceTintColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              TvTokens.pagePaddingV,
              24,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Queue',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${queue.length} ${queue.length == 1 ? 'song' : 'songs'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TvIconButton(
                  icon: Icons.playlist_remove,
                  size: 40,
                  iconSize: 20,
                  onSelect: queue.isEmpty
                      ? null
                      : () => unawaited(
                          ref.read(playbackProvider.notifier).clearQueue(),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: queue.isEmpty
                ? const Center(child: Text('Nothing in queue'))
                : ListView.builder(
                    controller: _scroll,
                    itemExtent: _rowHeight,
                    itemCount: queue.length,
                    itemBuilder: (context, position) => _QueueRow(
                      song: queue[position],
                      isPlaying: position == index,
                      focusNode: position == index ? _currentRow : null,
                      onSelect: () =>
                          unawaited(widget.controls.skipTo(position)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow({
    required this.song,
    required this.isPlaying,
    required this.onSelect,
    this.focusNode,
  });

  final LibraryItem song;
  final bool isPlaying;
  final VoidCallback onSelect;
  final FocusNode? focusNode;

  static const _coverSize = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onPrimary.withValues(alpha: 0.6);
    final playingColor = theme.bottomSheetTheme.backgroundColor?.withValues(
      alpha: 0.75,
    );
    final quality = song.audioSources.firstOrNull;

    return TvFocusable(
      onSelect: onSelect,
      focusNode: focusNode,
      debugLabel: 'queue:${song.name}',
      builder: (context, focused) => AnimatedContainer(
        duration: TvTokens.focusDuration,
        curve: TvTokens.focusCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: focused
            ? TvTokens.listFocus(context)
            : (isPlaying ? playingColor : Colors.transparent),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image(
                image: ref
                    .read(imageServiceProvider)
                    .itemImage(song, size: 128),
                width: _coverSize,
                height: _coverSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  Images.album,
                  width: _coverSize,
                  height: _coverSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          song.artistLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, height: 1.2),
                        ),
                      ),
                      if (quality != null) ...[
                        const SizedBox(width: 6),
                        AudioQualityBadge(
                          codec: quality.codec,
                          bitRate: quality.bitRate,
                          fontSize: 9,
                          textColor: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatPlaybackTime(song.duration),
              style: TextStyle(fontSize: 12, color: secondary),
            ),
            if (song.userData.isFavorite) ...[
              const SizedBox(width: 10),
              const Icon(CupertinoIcons.heart_fill, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
