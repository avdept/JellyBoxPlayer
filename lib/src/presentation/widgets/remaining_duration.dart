import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

class RemainingDuration extends ConsumerWidget {
  const RemainingDuration({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackProvider);
    final remaining = playbackState.totalDuration == null ? Duration.zero : playbackState.totalDuration! - playbackState.position;
    return Text(RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$').firstMatch('$remaining')?.group(1) ?? '$remaining', style: Theme.of(context).textTheme.bodySmall);
  }
}

