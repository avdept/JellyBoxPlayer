import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ArtworkCache extends CacheManager {
  ArtworkCache._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 90),
          maxNrOfCacheObjects: 5000,
        ),
      );

  static const key = 'jellyboxArtwork';

  static final ArtworkCache instance = ArtworkCache._();

  Future<String?> pathFor(String url) async {
    try {
      final cached = await getFileFromCache(url);
      if (cached != null) return cached.file.path;
      return (await getSingleFile(url)).path;
    } on Object {
      return null;
    }
  }
}
