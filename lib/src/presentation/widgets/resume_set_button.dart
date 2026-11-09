import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/resume_points_provider.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';

String resumePointLabel(ResumePoint point) =>
    '${point.songName} · ${_clock(point.position)}';

String _clock(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % Duration.secondsPerMinute;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

Future<void> resumeSet(
  BuildContext context,
  WidgetRef ref,
  ResumePoint point,
) async {
  final playback = ref.read(playbackProvider);
  if (playback.sourceId == point.item.id && !playback.status.isStopped) {
    if (!playback.status.isPlaying) {
      await ref.read(playbackProvider.notifier).resume();
    }
    return;
  }
  final name = point.item.name;
  SetPlaybackResult result;
  try {
    result = await ref.read(setPlaybackProvider.notifier).resume(point);
  } on Object {
    result = SetPlaybackResult.empty;
  }
  if (result == SetPlaybackResult.empty && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Nothing to resume in "$name"')));
  }
}

class ResumeSetButton extends ConsumerWidget {
  const ResumeSetButton({required this.item, super.key});

  final LibraryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final point = ref.watch(resumePointProvider(item.id));
    if (point == null) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.onPrimary;
    final busy = ref.watch(setPlaybackProvider) == item.id;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Tooltip(
        message: resumePointLabel(point),
        child: OutlinedButton.icon(
          onPressed: busy ? null : () => resumeSet(context, ref, point),
          icon: const Icon(Icons.play_circle_outline, size: 18),
          label: const Text('Resume'),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: VisualDensity.compact,
            shape: const StadiumBorder(),
          ),
        ),
      ),
    );
  }
}
