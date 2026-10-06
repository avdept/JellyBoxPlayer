import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ArtworkCache extends CacheManager {
  ArtworkCache._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 90),
          maxNrOfCacheObjects: 5000,
          fileService: _RoutedFileService(),
        ),
      );

  static const key = 'jellyboxArtwork';

  static final ArtworkCache instance = ArtworkCache._();

  static ArtworkRoute route = const ArtworkRoute();

  static String cacheKeyFor(String url) => route.keyFor(url);

  Future<String?> pathFor(String url) async {
    final cacheKey = cacheKeyFor(url);
    try {
      final cached = await getFileFromCache(cacheKey);
      if (cached != null) return cached.file.path;
      return (await getSingleFile(url, key: cacheKey)).path;
    } on Object {
      return null;
    }
  }
}

class ArtworkRoute {
  const ArtworkRoute({this.addresses = const [], this.active});

  final List<String> addresses;
  final String? active;

  String keyFor(String url) {
    final base = _baseOf(url);
    return base == null ? url : url.substring(base.length);
  }

  String fetchUrl(String url) {
    final base = _baseOf(url);
    final target = active;
    return base == null || target == null
        ? url
        : target + url.substring(base.length);
  }

  String? _baseOf(String url) {
    for (final base in addresses) {
      if (!url.startsWith(base)) continue;
      final rest = url.substring(base.length);
      if (rest.isEmpty || rest.startsWith('/') || rest.startsWith('?')) {
        return base;
      }
    }
    return null;
  }
}

class _RoutedFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) =>
      super.get(ArtworkCache.route.fetchUrl(url), headers: headers);
}
