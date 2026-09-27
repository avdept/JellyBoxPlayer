import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

class PositionSlider extends ConsumerStatefulWidget {
  const PositionSlider({super.key}) : _followsBar = false;

  const PositionSlider.bar({super.key}) : _followsBar = true;

  final bool _followsBar;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PositionSliderState();
}

class _PositionSliderState extends ConsumerState<PositionSlider> {
  // final _sliderKey = GlobalKey(debugLabel: 'slider');
  // bool isUserInteracting = false;
  // double? temporaryUserPosition;

  @override
  Widget build(BuildContext context) {
    if (widget._followsBar) {
      final progress = ref.watch(barProgressProvider);
      return Offstage(
        offstage: progress.stopped,
        child: SeekBar(
          duration: progress.duration,
          position: progress.position,
          bufferedPosition: progress.buffered,
          onChangeEnd: ref.read(barControlsProvider).seek,
        ),
      );
    }

    final playbackState = ref.watch(playbackProvider);

    return Offstage(
      offstage: playbackState.status == PlaybackStatus.stopped,
      child: SeekBar(
        duration: playbackState.totalDuration ?? Duration.zero,
        // Workaround for a bug where negative positions are passed which triggers an assert that stops the debugger
        // Tracked in #79
        position: playbackState.position >= Duration.zero
            ? playbackState.position
            : Duration.zero,
        bufferedPosition: playbackState.cacheProgress,
        onChangeEnd: (value) => ref.read(playbackProvider.notifier).seek(value),
      ),
    );
    // return GestureDetector(
    //   onHorizontalDragDown: (details) {
    //     final sliderWidth = _sliderKey.currentContext?.size?.width;
    //     if (sliderWidth == null) return;
    //   },
    //   onHorizontalDragUpdate: (details) {
    //     final sliderWidth = _sliderKey.currentContext?.size?.width;
    //     if (sliderWidth == null) return;
    //   },
    //   behavior: HitTestBehavior.opaque,
    //   child: Slider(
    //     key: _sliderKey,
    //     value: isUserInteracting
    //         ? temporaryUserPosition!
    //         : min(playbackState.position.inSeconds.toDouble(), playbackState.totalDuration?.inSeconds.toDouble() ?? 0),
    //     max: playbackState.totalDuration?.inSeconds.toDouble() ?? 0,
    //     onChangeEnd: (value) {
    //       setState(() {
    //         isUserInteracting = false;
    //         temporaryUserPosition = null;
    //       });
    //       print("Seek to: ${value.toInt()}");
    //       ref.read(playbackProvider.notifier).seek(Duration(seconds: value.toInt()));
    //     },
    //     onChanged: (value) => {
    //       setState(() {
    //         temporaryUserPosition = value;
    //       }),
    //     },
    //     onChangeStart: (value) => {
    //       setState(() {
    //         isUserInteracting = true;
    //         temporaryUserPosition = value;
    //       }),
    //     },
    //   ),
    // );
  }
}

class SeekBar extends StatefulWidget {
  const SeekBar({
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    super.key,
    this.onChanged,
    this.onChangeEnd,
  });
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  @override
  SeekBarState createState() => SeekBarState();
}

class SeekBarState extends State<SeekBar> {
  static const _hoverThumbRadius = 8.0;

  double? _dragValue;
  double? _hoverX;
  late SliderThemeData _sliderThemeData;
  final _hoverTooltip = OverlayPortalController();
  final _hoverLink = LayerLink();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 2,
    );
  }

  double get _trackInset {
    final overlay =
        (_sliderThemeData.overlayShape ?? const RoundSliderOverlayShape())
            .getPreferredSize(true, false)
            .width;
    const thumb = RoundSliderThumbShape(enabledThumbRadius: _hoverThumbRadius);
    return max(overlay, thumb.getPreferredSize(true, false).width) / 2;
  }

  void _onHover(PointerHoverEvent event) {
    setState(() => _hoverX = event.localPosition.dx);
    if (!_hoverTooltip.isShowing) _hoverTooltip.show();
  }

  void _onExit(PointerExitEvent _) {
    setState(() => _hoverX = null);
    if (_hoverTooltip.isShowing) _hoverTooltip.hide();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            SliderTheme(
              data: _sliderThemeData.copyWith(
                thumbShape: SliderComponentShape.noThumb,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
              ),
              child: ExcludeSemantics(
                child: Slider(
                  max: widget.duration.inMilliseconds.toDouble(),
                  value: min(
                    widget.bufferedPosition.inMilliseconds.toDouble(),
                    widget.duration.inMilliseconds.toDouble(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _dragValue = value;
                    });
                    if (widget.onChanged != null) {
                      widget.onChanged!(Duration(milliseconds: value.round()));
                    }
                  },
                  onChangeEnd: (value) {
                    if (widget.onChangeEnd != null) {
                      widget.onChangeEnd!(
                        Duration(milliseconds: value.round()),
                      );
                    }
                    _dragValue = null;
                  },
                ),
              ),
            ),
            SliderTheme(
              data: _sliderThemeData.copyWith(
                inactiveTrackColor: Colors.transparent,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: _hoverThumbRadius,
                ),
              ),
              child: Slider(
                max: widget.duration.inMilliseconds.toDouble(),
                value: min(
                  _dragValue ?? widget.position.inMilliseconds.toDouble(),
                  widget.duration.inMilliseconds.toDouble(),
                ),
                onChanged: (value) {
                  setState(() {
                    _dragValue = value;
                  });
                  if (widget.onChanged != null) {
                    widget.onChanged!(Duration(milliseconds: value.round()));
                  }
                },
                onChangeEnd: (value) {
                  if (widget.onChangeEnd != null) {
                    widget.onChangeEnd!(Duration(milliseconds: value.round()));
                  }
                  setState(() => _dragValue = null);
                },
              ),
            ),
            _hoverPreview(constraints.maxWidth),
          ],
        ),
      ),
    );
  }

  Widget _hoverPreview(double width) {
    final hoverX = _hoverX;
    final durationMs = widget.duration.inMilliseconds;
    final inset = _trackInset;
    final trackWidth = width - inset * 2;
    final active = hoverX != null && durationMs > 0 && trackWidth > 0;

    final fraction = !active
        ? 0.0
        : _dragValue != null
        ? (_dragValue! / durationMs).clamp(0.0, 1.0)
        : ((hoverX - inset) / trackWidth).clamp(0.0, 1.0);
    final target = Duration(milliseconds: (durationMs * fraction).round());
    final colors = Theme.of(context).colorScheme;
    final thumbColor = _sliderThemeData.thumbColor ?? colors.primary;
    final showsGhost = active && _dragValue == null;

    return Positioned(
      left: inset + max(trackWidth, 0) * fraction - _hoverThumbRadius,
      width: _hoverThumbRadius * 2,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: CompositedTransformTarget(
            link: _hoverLink,
            child: OverlayPortal(
              controller: _hoverTooltip,
              overlayChildBuilder: (context) => Align(
                alignment: Alignment.topLeft,
                child: CompositedTransformFollower(
                  link: _hoverLink,
                  targetAnchor: Alignment.topCenter,
                  followerAnchor: Alignment.bottomCenter,
                  offset: const Offset(0, -6),
                  child: IgnorePointer(
                    child: active
                        ? _HoverTimeBubble(label: formatPlaybackTime(target))
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              child: Container(
                width: _hoverThumbRadius * 2,
                height: _hoverThumbRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: showsGhost
                      ? thumbColor.withValues(alpha: 0.45)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}

class _HoverTimeBubble extends StatelessWidget {
  const _HoverTimeBubble({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: Themes.tooltipDecoration,
    child: Padding(
      padding: Themes.tooltipPadding,
      child: Text(
        label,
        style: Themes.tooltipTextStyle.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}
