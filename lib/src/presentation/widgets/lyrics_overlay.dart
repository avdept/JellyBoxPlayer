import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

class LyricsView extends ConsumerWidget {
  const LyricsView({
    this.padding = const EdgeInsets.symmetric(vertical: 24),
    super.key,
  });

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final song = ref.watch(currentSongProvider);

    if (song == null || !song.hasLyrics) {
      return const _Message('No lyrics for this track');
    }

    return _LyricsBody(
      key: ValueKey(song.id),
      songId: song.id,
      device: device,
      padding: padding,
    );
  }
}

class LyricsOverlay extends ConsumerWidget {
  const LyricsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(lyricsShownProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isVisible
          ? const _LyricsPanel(key: ValueKey(true))
          : const SizedBox.expand(key: ValueKey(false)),
    );
  }
}

class _LyricsPanel extends ConsumerWidget {
  const _LyricsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: ColoredBox(
          color: Colors.black.withOpacity(0.45),
          child: SafeArea(
            child: Column(
              children: [
                _header(context, ref, song),
                const Expanded(
                  child: LyricsView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, LibraryItem? song) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 16, 12, 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song?.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (song?.albumArtist != null) ...[
                const SizedBox(height: 2),
                Text(
                  song!.albumArtist!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              ref.read(lyricsVisibleProvider.notifier).state = false,
          color: Colors.white,
          tooltip: 'Close lyrics',
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

class _LyricsBody extends ConsumerStatefulWidget {
  const _LyricsBody({
    required this.songId,
    required this.device,
    required this.padding,
    super.key,
  });

  final String songId;
  final DeviceType device;
  final EdgeInsets padding;

  @override
  ConsumerState<_LyricsBody> createState() => _LyricsBodyState();
}

class _LyricsBodyState extends ConsumerState<_LyricsBody> {
  List<GlobalKey> _lineKeys = const [];
  int _activeLine = -1;
  bool _didInitialSync = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      playbackProvider.select((state) => state.position),
      (_, position) => _syncActiveLine(position),
    );
  }

  void _syncActiveLine(Duration position) {
    final lyrics = ref.read(lyricsProvider(widget.songId)).valueOrNull;
    if (lyrics == null || !lyrics.isSynced) return;

    final shifted = position + lyrics.offset;
    var index = -1;
    for (var i = 0; i < lyrics.lyrics.length; i++) {
      final start = lyrics.lyrics[i].startTime;
      if (start == null) continue;
      if (start > shifted) break;
      index = i;
    }

    if (index == _activeLine || !mounted) return;
    setState(() => _activeLine = index);
    _scrollToActiveLine();
  }

  void _scrollToActiveLine() {
    if (_activeLine < 0 || _activeLine >= _lineKeys.length) return;
    final lineContext = _lineKeys[_activeLine].currentContext;
    if (lineContext == null) return;
    unawaited(
      Scrollable.ensureVisible(
        lineContext,
        alignment: 0.4,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = ref.watch(lyricsProvider(widget.songId));

    return lyrics.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      error: (_, _) => const _Message("Couldn't load lyrics"),
      data: (lyrics) {
        final lines = lyrics?.lyrics ?? const <LyricLineDTO>[];
        if (lines.isEmpty) return const _Message('No lyrics for this track');

        if (_lineKeys.length != lines.length) {
          _lineKeys = List.generate(lines.length, (_) => GlobalKey());
        }
        if (!_didInitialSync) {
          _didInitialSync = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncActiveLine(ref.read(playbackProvider).position);
          });
        }

        final isSynced = lyrics!.isSynced;

        return SingleChildScrollView(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < lines.length; i++)
                _line(i, lines[i], isSynced: isSynced),
            ],
          ),
        );
      },
    );
  }

  Widget _line(int index, LyricLineDTO line, {required bool isSynced}) {
    final isActive = isSynced && index == _activeLine;
    final start = line.startTime;
    final text = line.text.trim();

    return Padding(
      key: _lineKeys[index],
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: (isSynced && start != null)
            ? () => ref.read(playbackProvider.notifier).seek(start)
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: (!isSynced || isActive)
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            fontSize: isActive
                ? (widget.device.isMobile ? 24 : 30)
                : (widget.device.isMobile ? 19 : 24),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            height: 1.35,
          ),
          child: Text(text.isEmpty ? '♪' : text, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 18,
      ),
    ),
  );
}
