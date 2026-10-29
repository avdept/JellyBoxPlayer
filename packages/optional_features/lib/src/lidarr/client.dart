// The stub keeps the real constructor's shape so the app compiles unchanged.
// ignore_for_file: avoid_unused_constructor_parameters

import 'package:optional_features/src/lidarr/models.dart';

class LidarrClient {
  LidarrClient({
    required String baseUrl,
    required String apiKey,
    Object? dio,
    String? userAgent,
  });

  static const monitorAll = 'all';
  static const monitorNone = 'none';

  bool get available => false;

  static String normalizeBaseUrl(String value) => value.trim();

  Future<LidarrSystem> status() => _unavailable();

  Future<List<LidarrRootFolder>> rootFolders() => _unavailable();

  Future<List<LidarrProfile>> qualityProfiles() => _unavailable();

  Future<List<LidarrProfile>> metadataProfiles() => _unavailable();

  Future<List<LidarrArtist>> searchArtists(String term) => _unavailable();

  Future<LidarrArtist?> lookupArtist(String mbid) => _unavailable();

  Future<List<LidarrAlbum>> searchAlbums(String term) => _unavailable();

  Future<LidarrAlbum?> lookupAlbum(String releaseGroupId) => _unavailable();

  Future<List<LidarrArtist>> artists() => _unavailable();

  Future<LidarrArtist?> artistByMbid(String mbid) => _unavailable();

  Future<List<LidarrAlbum>> albums({int? artistId, String? foreignAlbumId}) =>
      _unavailable();

  Future<LidarrAlbum?> albumByReleaseGroup(String releaseGroupId) =>
      _unavailable();

  Future<LidarrArtist> addArtist(
    LidarrArtist artist, {
    required LidarrAddDefaults defaults,
    bool search = true,
  }) => _unavailable();

  Future<LidarrAlbum> addAlbum(
    LidarrAlbum album, {
    required LidarrAddDefaults defaults,
    bool search = true,
  }) => _unavailable();

  Future<void> searchAlbum(int albumId) => _unavailable();

  Future<void> searchArtist(int artistId) => _unavailable();

  Future<List<LidarrQueueItem>> queue({List<int> artistIds = const []}) =>
      _unavailable();

  Future<T> _unavailable<T>() => Future<T>.error(
    const LidarrException('Lidarr support is not part of this build'),
  );
}
