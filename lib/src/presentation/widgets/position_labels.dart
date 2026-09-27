import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

class PositionLabels extends ConsumerWidget {
  const PositionLabels({
    this.fontSize = 13,
    this.middle,
    super.key,
  }) : _followsBar = false;

  const PositionLabels.bar({
    this.fontSize = 13,
    this.middle,
    super.key,
  }) : _followsBar = true;

  final bool _followsBar;

  final double fontSize;
  final Widget? middle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (positionSeconds, total) = _followsBar
        ? ref.watch(
            barProgressProvider.select(
              (progress) => (progress.position.inSeconds, progress.duration),
            ),
          )
        : ref.watch(
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
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(formatPlaybackTime(position), style: style),
            ),
          ),
          ?middle,
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('-${formatPlaybackTime(remaining)}', style: style),
            ),
          ),
        ],
      ),
    );
  }
}
