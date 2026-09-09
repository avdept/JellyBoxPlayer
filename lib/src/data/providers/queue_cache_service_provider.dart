import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/downloads/cache_downloader.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/queue_cache_database_provider.dart';
import 'package:jplayer/src/data/services/queue_cache_service.dart';

final cacheDownloaderProvider = Provider<CacheDownloader>(
  (ref) => BackgroundCacheDownloader(),
);

final queueCacheServiceProvider = Provider<QueueCacheService>(
  (ref) => QueueCacheService(
    database: ref.watch(queueCacheDatabaseProvider),
    downloads: ref.watch(downloadDatabaseProvider),
    downloader: ref.watch(cacheDownloaderProvider),
    deviceId: deviceId,
  ),
);
