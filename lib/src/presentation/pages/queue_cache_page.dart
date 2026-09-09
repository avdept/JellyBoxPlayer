import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/queue_cache_database.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/queue_cache_report_provider.dart';

class QueueCachePage extends ConsumerWidget {
  const QueueCachePage({super.key});

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB'];
    var value = bytes / 1024;
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unit]}';
  }

  static String formatAge(DateTime moment) {
    final elapsed = DateTime.now().difference(moment);
    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }

  Future<void> _purge(WidgetRef ref) async {
    await ref.read(queueCacheServiceProvider).purge();
    ref.invalidate(queueCacheReportProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final limit = ref.watch(forwardCacheLimitProvider);
    final report = ref.watch(queueCacheReportProvider);
    final playback = ref.watch(playbackProvider);
    final queueIds = {for (final song in playback.songs) song.id};
    final playingIndex = playback.currentMediaIndex;
    final playingId = playingIndex != null
        ? playback.songs.elementAtOrNull(playingIndex)?.id
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue cache'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(queueCacheReportProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => _purge(ref),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Purge cache',
          ),
        ],
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (entries) {
          final used = entries.fold(0, (sum, e) => sum + e.sizeInBytes);
          final missing = entries.where((e) => !e.onDisk).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _summary(
                theme: theme,
                limit: limit,
                used: used,
                count: entries.length,
                missing: missing,
                queued: entries
                    .where((e) => queueIds.contains(e.item.id))
                    .length,
              ),
              const Divider(height: 1),
              if (entries.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      limit.isEnabled
                          ? 'Nothing cached yet'
                          : 'Caching is off',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) => _entryTile(
                      theme: theme,
                      entry: entries[index],
                      inQueue: queueIds.contains(entries[index].item.id),
                      isPlaying: entries[index].item.id == playingId,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _summary({
    required ThemeData theme,
    required ForwardCacheLimit limit,
    required int used,
    required int count,
    required int missing,
    required int queued,
  }) {
    final capacity = limit.isEnabled
        ? '${formatBytes(used)} of ${formatBytes(limit.bytes)}'
        : '${formatBytes(used)} (limit off)';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(capacity, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (limit.isEnabled)
            LinearProgressIndicator(
              value: (used / limit.bytes).clamp(0.0, 1.0),
              minHeight: 6,
            ),
          const SizedBox(height: 12),
          Text(
            '$count cached · $queued in this queue'
            '${missing > 0 ? ' · $missing missing on disk' : ''}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _entryTile({
    required ThemeData theme,
    required CacheDetail entry,
    required bool inQueue,
    required bool isPlaying,
  }) {
    final subtitle = [
      formatBytes(entry.sizeInBytes),
      'used ${formatAge(entry.lastUsedDate)}',
      if (!entry.onDisk) 'FILE MISSING',
    ].join(' · ');

    return ListTile(
      dense: true,
      leading: Icon(
        isPlaying
            ? Icons.play_arrow
            : entry.onDisk
            ? Icons.offline_pin_outlined
            : Icons.error_outline,
        color: entry.onDisk
            ? (isPlaying ? theme.colorScheme.primary : null)
            : theme.colorScheme.error,
      ),
      title: Text(entry.item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: inQueue
          ? Text('queue', style: theme.textTheme.labelSmall)
          : null,
    );
  }
}
