import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

class PositionSlider extends ConsumerStatefulWidget {
  const PositionSlider({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PositionSliderState();
}

class _PositionSliderState extends ConsumerState<PositionSlider> {
  final _sliderKey = GlobalKey(debugLabel: 'slider');
  bool isUserInteracting = false;
  double? temporaryUserPosition;

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackProvider);

    if (playbackState.status == PlaybackStatus.stopped) return Container();
    print("Playback status: ${playbackState.status}");
    return Positioned(
      left: -25,
      top: -22,
      right: -25,
      child: GestureDetector(
        onHorizontalDragDown: (details) {
          final sliderWidth = _sliderKey.currentContext?.size?.width;
          if (sliderWidth == null) return;
        },
        onHorizontalDragUpdate: (details) {
          final sliderWidth = _sliderKey.currentContext?.size?.width;
          if (sliderWidth == null) return;
        },
        behavior: HitTestBehavior.opaque,
        child: Slider(
          key: _sliderKey,
          value: isUserInteracting ? temporaryUserPosition! : playbackState.position.inSeconds.toDouble(),
          max: playbackState.totalDuration?.inSeconds.toDouble() ?? 0,
          onChangeEnd: (value) {
            setState(() {
              isUserInteracting = false;
              temporaryUserPosition = null;
            });
            print("Seek to: ${value.toInt()}");
            ref.read(playbackProvider.notifier).seek(Duration(seconds: value.toInt()));
          },
          onChanged: (value) => {
            setState(() {
              temporaryUserPosition = value;
            }),
          },
          onChangeStart: (value) => {
            setState(() {
              isUserInteracting = true;
              temporaryUserPosition = value;
            }),
          },
        ),
      ),
    );
  }
}
