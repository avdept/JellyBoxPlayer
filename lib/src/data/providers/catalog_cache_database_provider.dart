import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/storages/catalog_cache_database.dart';

final catalogCacheDatabaseProvider = Provider<CatalogCacheDatabase>(
  (ref) => CatalogCacheDatabase(ref.watch(downloadDatabaseProvider)),
);
