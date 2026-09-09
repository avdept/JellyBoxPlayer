import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/queue_cache_database.dart';
import 'package:jplayer/src/domain/providers/forward_cache_provider.dart';

final AutoDisposeFutureProvider<List<CacheDetail>> queueCacheReportProvider =
    FutureProvider.autoDispose<List<CacheDetail>>((ref) {
  ref.watch(forwardCacheProvider);
  return ref.watch(queueCacheDatabaseProvider).detailedEntries();
});
