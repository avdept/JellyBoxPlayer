import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

class PositionSlider extends ConsumerWidget {
  final _sliderKey = GlobalKey(debugLabel: 'slider');
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackProvider);

    return Positioned(
      left: -25,
      top: -22,
      right: -25,
      child: GestureDetector(
        onHorizontalDragDown: (details) {
          final sliderWidth = _sliderKey.currentContext?.size?.width;
          if (sliderWidth == null) return;
          // _playProgress.value = details.localPosition.dx / sliderWidth;
        },
        onHorizontalDragUpdate: (details) {
          final sliderWidth = _sliderKey.currentContext?.size?.width;
          if (sliderWidth == null) return;
          // _playProgress.value = details.localPosition.dx / sliderWidth;
        },
        behavior: HitTestBehavior.opaque,
        child: Slider(
          key: _sliderKey,
          min: 0,
          value: playbackState.position.inSeconds.toDouble(),
          max: playbackState.totalDuration?.inSeconds.toDouble() ?? 0,
          onChangeEnd: (value) => ref.read(playbackProvider.notifier).seek(Duration(seconds: value.toInt())),
          onChanged: (value) => {},
        ),
      ),
    );
  }
}
