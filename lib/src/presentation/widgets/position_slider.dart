import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';


class PositionSlider extends ConsumerStatefulWidget {
  const PositionSlider({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PositionSliderState();
}

class _PositionSliderState extends ConsumerState<PositionSlider> {
  // final _sliderKey = GlobalKey(debugLabel: 'slider');
  // bool isUserInteracting = false;
  // double? temporaryUserPosition;

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackProvider);

    if (playbackState.status == PlaybackStatus.stopped) return Container();
    return SeekBar(
      duration: playbackState.totalDuration ?? Duration.zero,
      position: playbackState.position,
      bufferedPosition: playbackState.cacheProgress,
      onChangeEnd: (value) => ref.read(playbackProvider.notifier).seek(value),
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
  double? _dragValue;
  late SliderThemeData _sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
              value: min(widget.bufferedPosition.inMilliseconds.toDouble(), widget.duration.inMilliseconds.toDouble()),
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
                _dragValue = null;
              },
            ),
          ),
        ),
        SliderTheme(
          data: _sliderThemeData.copyWith(
            inactiveTrackColor: Colors.transparent,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            max: widget.duration.inMilliseconds.toDouble(),
            value: min(_dragValue ?? widget.position.inMilliseconds.toDouble(), widget.duration.inMilliseconds.toDouble()),
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
              _dragValue = null;
            },
          ),
        ),
      ],
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}
