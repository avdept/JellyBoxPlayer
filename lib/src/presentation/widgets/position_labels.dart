import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

class PositionLabels extends ConsumerWidget {
  const PositionLabels({
    this.fontSize = 13,
    super.key,
  });

  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (positionSeconds, total) = ref.watch(
      playbackProvider.select(
        (state) => (
          state.position.isNegative ? 0 : state.position.inSeconds,
          state.totalDuration ?? Duration.zero,
        ),
      ),
    );
    final position = Duration(seconds: positionSeconds);
    final remaining = total - position;
    final style = TextStyle(
      fontSize: fontSize,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_formatDuration(position), style: style),
          Text('-${_formatDuration(remaining)}', style: style),
        ],
      ),
    );
  }

  static String _formatDuration(Duration value) {
    final duration = value < Duration.zero ? Duration.zero : value;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final mm = minutes.toString().padLeft(2, '0');
      return '$hours:$mm:$ss';
    }
    return '${duration.inMinutes}:$ss';
  }
}
