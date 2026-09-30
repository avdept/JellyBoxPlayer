import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';

class LyricsView extends ConsumerWidget {
  const LyricsView({
    this.padding = const EdgeInsets.symmetric(vertical: 24),
    super.key,
  });

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final song = ref.watch(barSongProvider);

    if (song == null) {
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
    final song = ref.watch(barSongProvider);

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

  Widget _header(BuildContext context, WidgetRef ref, LibraryItem? song) =>
      Padding(
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
              onPressed: () {
                ref.read(lyricsVisibleProvider.notifier).state = false;
                ref.read(studioModeLyricsProvider.notifier).state = true;
                ref.read(studioModeVisibleProvider.notifier).state = true;
              },
              color: Colors.white,
              tooltip: 'Studio mode',
              icon: const Icon(Icons.fullscreen),
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

class _LyricsBodyState extends ConsumerState<_LyricsBody>
    with SingleTickerProviderStateMixin {
  static const _maxExtrapolation = Duration(milliseconds: 1500);

  final _clock = ValueNotifier<Duration>(Duration.zero);
  final _sinceAnchor = Stopwatch();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _anchor = Duration.zero;
  bool _playing = false;
  List<GlobalKey> _lineKeys = const [];
  int _activeLine = -1;
  bool _didInitialSync = false;

  @override
  void initState() {
    super.initState();
    _clock.addListener(() => _syncActiveLine(_clock.value));
    ref
      ..listenManual(
        barProgressProvider.select((progress) => progress.position),
        (_, position) => _anchorAt(position),
      )
      ..listenManual(barPlayingProvider, (_, playing) {
        _playing = playing;
        _updateTicker();
      }, fireImmediately: true)
      ..listenManual(
        lyricsProvider(widget.songId),
        (_, _) => _updateTicker(),
      );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _anchorAt(Duration position) {
    _anchor = position;
    _sinceAnchor
      ..reset()
      ..start();
    _clock.value = position;
  }

  void _onTick(Duration _) {
    final elapsed = _sinceAnchor.elapsed;
    _clock.value =
        _anchor + (elapsed > _maxExtrapolation ? _maxExtrapolation : elapsed);
  }

  void _updateTicker() {
    final lyrics = ref.read(lyricsProvider(widget.songId)).valueOrNull;
    final shouldRun = _playing && (lyrics?.hasWordCues ?? false);
    if (shouldRun && !_ticker.isActive) {
      _anchorAt(_clock.value);
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
      _clock.value = _anchor;
    }
  }

  void _syncActiveLine(Duration position) {
    final lyrics = ref.read(lyricsProvider(widget.songId)).valueOrNull;
    if (lyrics == null || !lyrics.isSynced) return;

    final shifted = position + lyrics.offset;
    var index = -1;
    for (var i = 0; i < lyrics.lines.length; i++) {
      final start = lyrics.lines[i].start;
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
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(child: TextLinesShimmer(count: 7)),
      ),
      error: (_, _) => const _Message("Couldn't load lyrics"),
      data: (lyrics) {
        final lines = lyrics?.lines ?? const <LyricLine>[];
        if (lines.isEmpty) return const _Message('No lyrics for this track');

        if (_lineKeys.length != lines.length) {
          _lineKeys = List.generate(lines.length, (_) => GlobalKey());
        }
        if (!_didInitialSync) {
          _didInitialSync = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _anchorAt(ref.read(barProgressProvider).position);
              _syncActiveLine(_clock.value);
            }
          });
        }

        final isSynced = lyrics!.isSynced;

        return SingleChildScrollView(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < lines.length; i++)
                _line(
                  i,
                  lines[i],
                  isSynced: isSynced,
                  offset: lyrics.offset,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _line(
    int index,
    LyricLine line, {
    required bool isSynced,
    required Duration offset,
  }) {
    final isActive = isSynced && index == _activeLine;
    final start = line.start;
    final trimmed = line.text.trim();
    final text = trimmed.isEmpty ? '♪' : trimmed;

    return AnimatedPadding(
      key: _lineKeys[index],
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        vertical: switch ((isSynced, isActive)) {
          (false, _) => 8,
          (true, true) => widget.device.isMobile ? 14 : 20,
          (true, false) => 3,
        },
      ),
      child: GestureDetector(
        onTap: (isSynced && start != null)
            ? () => ref.read(barControlsProvider).seek(start)
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
          child: isActive
              ? _ActiveLineText(
                  line: line,
                  text: text,
                  leading: line.text.length - line.text.trimLeft().length,
                  clock: _clock,
                  offset: offset,
                )
              : Text(text, textAlign: TextAlign.center),
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

class _ActiveLineText extends StatefulWidget {
  const _ActiveLineText({
    required this.line,
    required this.text,
    required this.leading,
    required this.clock,
    required this.offset,
  });

  final LyricLine line;
  final String text;
  final int leading;
  final ValueListenable<Duration> clock;
  final Duration offset;

  @override
  State<_ActiveLineText> createState() => _ActiveLineTextState();
}

class _ActiveLineTextState extends State<_ActiveLineText> {
  final _base = TextPainter(textAlign: TextAlign.center);
  final _sung = TextPainter(textAlign: TextAlign.center);

  @override
  void dispose() {
    _base.dispose();
    _sung.dispose();
    super.dispose();
  }

  void _layout(TextStyle style, double maxWidth) {
    final color = style.color ?? Colors.white;
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    for (final (painter, paintColor) in [
      (_base, color.withValues(alpha: color.a * 0.45)),
      (_sung, color),
    ]) {
      painter
        ..text = TextSpan(
          text: widget.text,
          style: style.copyWith(color: paintColor),
        )
        ..textDirection = direction
        ..textScaler = scaler
        ..layout(maxWidth: maxWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return LayoutBuilder(
      builder: (context, constraints) {
        _layout(style, constraints.maxWidth);
        return CustomPaint(
          painter: _ActiveLinePainter(
            base: _base,
            sung: _sung,
            line: widget.line,
            text: widget.text,
            leading: widget.leading,
            clock: widget.clock,
            offset: widget.offset,
            fontSize: style.fontSize ?? 14,
          ),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.transparent),
          ),
        );
      },
    );
  }
}

class _ActiveLinePainter extends CustomPainter {
  _ActiveLinePainter({
    required this.base,
    required this.sung,
    required this.line,
    required this.text,
    required this.leading,
    required this.clock,
    required this.offset,
    required this.fontSize,
  }) : super(repaint: line.cues.isEmpty ? null : clock);

  static const _glowOpacity = 0.85;

  final TextPainter base;
  final TextPainter sung;
  final LyricLine line;
  final String text;
  final int leading;
  final ValueListenable<Duration> clock;
  final Duration offset;
  final double fontSize;

  double get _bleed => fontSize * 0.25;

  double get _glow => fontSize * 0.3;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset((size.width - base.width) / 2, 0);
    if (line.cues.isEmpty) {
      _paintGlowing(canvas, size, origin, null);
      return;
    }

    base.paint(canvas, origin);
    final clip = _sungClip();
    if (clip != null) _paintGlowing(canvas, size, origin, clip);
  }

  Path? _sungClip() {
    final progress = line.wordProgressAt(clock.value + offset);
    if (progress == null) return null;

    final wordStart = (progress.cue.position - leading).clamp(0, text.length);
    var wordEnd = (progress.cue.endPosition - leading).clamp(
      wordStart,
      text.length,
    );
    while (wordEnd > wordStart && text[wordEnd - 1].trim().isEmpty) {
      wordEnd--;
    }

    final clip = Path();
    for (final box in sung.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: wordStart),
    )) {
      clip.addRect(_bled(box.toRect()));
    }

    final wordBoxes = sung.getBoxesForSelection(
      TextSelection(baseOffset: wordStart, extentOffset: wordEnd),
    );
    var remaining =
        wordBoxes.fold<double>(0, (sum, box) => sum + box.right - box.left) *
        progress.fraction;
    for (final box in wordBoxes) {
      if (remaining <= 0) break;
      final width = remaining.clamp(0.0, box.right - box.left);
      remaining -= width;
      final left = box.direction == TextDirection.rtl
          ? box.right - width
          : box.left;
      clip.addRect(
        _bled(Rect.fromLTWH(left, box.top, width, box.bottom - box.top)),
      );
    }
    return clip;
  }

  void _paintGlowing(Canvas canvas, Size size, Offset origin, Path? clip) {
    canvas.saveLayer(
      (Offset.zero & size).inflate(_glow * 3),
      Paint()
        ..color = Colors.white.withValues(alpha: _glowOpacity)
        ..imageFilter = ImageFilter.blur(sigmaX: _glow, sigmaY: _glow),
    );
    _paintSung(canvas, origin, clip);
    canvas.restore();
    _paintSung(canvas, origin, clip);
  }

  void _paintSung(Canvas canvas, Offset origin, Path? clip) {
    canvas
      ..save()
      ..translate(origin.dx, origin.dy);
    if (clip != null) canvas.clipPath(clip);
    sung.paint(canvas, Offset.zero);
    canvas.restore();
  }

  Rect _bled(Rect rect) => Rect.fromLTRB(
    rect.left,
    rect.top - _bleed,
    rect.right,
    rect.bottom + _bleed,
  );

  @override
  bool shouldRepaint(_ActiveLinePainter old) => true;
}
