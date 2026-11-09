import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/playback_storage.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/resume_points_provider.dart';
import 'package:jplayer/src/presentation/pages/queue_cache_page.dart';
import 'package:jplayer/src/presentation/widgets/resume_set_button.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';

final _allResumePointsProvider = FutureProvider.autoDispose<List<ResumePoint>>(
  (ref) {
    ref.watch(resumePointsChangedProvider);
    return ref.watch(resumePointDatabaseProvider).all();
  },
);

final _queueSnapshotProvider = FutureProvider.autoDispose<PlaybackSnapshot?>((
  ref,
) {
  final serverId = ref.watch(currentServerIdProvider);
  if (serverId == null || serverId.isEmpty) return Future.value();
  return PlaybackStorage().load(serverId);
});

class DevQueuesPage extends ConsumerWidget {
  const DevQueuesPage({super.key});

  void _refresh(WidgetRef ref) => ref
    ..invalidate(_allResumePointsProvider)
    ..invalidate(_queueSnapshotProvider);

  Future<void> _delete(WidgetRef ref, ResumePoint point) async {
    await ref.read(resumePointDatabaseProvider).delete(point.item.id);
    ref.read(resumePointsChangedProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final points = ref.watch(_allResumePointsProvider);
    final snapshot = ref.watch(_queueSnapshotProvider);
    final playback = ref.watch(playbackProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved queues'),
        actions: [
          IconButton(
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _header(theme, 'Live queue'),
          _liveQueue(theme, playback),
          _header(theme, 'Restore snapshot (SharedPreferences)'),
          snapshot.when(
            loading: () => const ListTile(title: Text('Loading…')),
            error: (error, _) => ListTile(title: Text('$error')),
            data: (saved) => _snapshot(theme, saved),
          ),
          _header(theme, 'Resume points (downloads.db)'),
          points.when(
            loading: () => const ListTile(title: Text('Loading…')),
            error: (error, _) => ListTile(title: Text('$error')),
            data: (list) => list.isEmpty
                ? const ListTile(title: Text('No resume points'))
                : Column(
                    children: [
                      for (final point in list)
                        _pointTile(context, ref, theme, point, now),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(text, style: theme.textTheme.titleMedium),
  );

  Widget _liveQueue(ThemeData theme, PlaybackState playback) {
    final index = playback.currentMediaIndex;
    final song = index != null ? playback.songs.elementAtOrNull(index) : null;
    final lines = [
      'status ${playback.status.name}',
      'songs ${playback.songs.length}',
      'index ${index ?? '-'} · ${song?.name ?? '-'}',
      'position ${_clock(playback.position)}',
      'album ${playback.album?.name ?? '-'} (${playback.album?.id ?? '-'})',
      'sourceId ${playback.sourceId ?? '-'}',
      'shuffle ${playback.shuffleEnabled}',
    ];
    return _lines(theme, lines);
  }

  Widget _snapshot(ThemeData theme, PlaybackSnapshot? saved) {
    if (saved == null) return _lines(theme, const ['nothing saved']);
    final song = saved.songs
        .where((song) => song.id == saved.songId)
        .firstOrNull;
    return _lines(theme, [
      'songs ${saved.songs.length}',
      'song ${song?.name ?? saved.songId}',
      'position ${_clock(Duration(milliseconds: saved.positionMs))}',
      'album ${saved.album.name} (${saved.album.id})',
      'sourceId ${saved.sourceId ?? '-'}',
      'shuffle ${saved.shuffle}'
          '${saved.unshuffledOrder != null ? ' · order kept' : ''}',
    ]);
  }

  Widget _lines(ThemeData theme, List<String> lines) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: SelectableText(
      lines.join('\n'),
      style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
    ),
  );

  Widget _pointTile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ResumePoint point,
    DateTime now,
  ) {
    final age = now.difference(point.updatedAt);
    final flags = [
      if (!isResumable(point)) 'hidden: start of first song',
      if (age > resumePointMaxAge) 'hidden: older than 60 days',
    ];
    final subtitle = [
      '${point.item.kind.name} ${point.item.id}',
      '${point.songName} · ${point.songIndex + 1}/${point.songCount} '
          '· ${_clock(point.position)}',
      'updated ${QueueCachePage.formatAge(point.updatedAt)}'
          '${flags.isEmpty ? '' : ' · ${flags.join(' · ')}'}',
    ].join('\n');

    return ListTile(
      dense: true,
      isThreeLine: true,
      leading: Icon(
        flags.isEmpty ? Icons.bookmark_outline : Icons.visibility_off_outlined,
        color: flags.isEmpty ? null : theme.colorScheme.error,
      ),
      title: Text(point.item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: SelectableText(subtitle, style: theme.textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => resumeSet(context, ref, point),
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Resume',
          ),
          IconButton(
            onPressed: () => _delete(ref, point),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  static String _clock(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % Duration.secondsPerMinute;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
