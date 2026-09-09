import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/storages/queue_cache_database.dart';

final queueCacheDatabaseProvider = Provider<QueueCacheDatabase>(
  (ref) => QueueCacheDatabase(ref.watch(downloadDatabaseProvider)),
);
