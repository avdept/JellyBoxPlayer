import 'package:dio/dio.dart';
import 'package:jplayer/src/core/audio/audio_stream_profile.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/backend/item_image_ref.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_playlist_generator.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/mappers/item_dto_mapper.dart';
import 'package:jplayer/src/data/backend/mappers/lyrics_dto_mapper.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/media_server_exception.dart';
import 'package:jplayer/src/data/backend/mediabrowser_query.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/domain/models/models.dart';

class JellyfinClient implements MediaServerClient {
  JellyfinClient({
    required Dio dio,
    required String baseUrl,
    required this.userId,
    required this.token,
    required this.deviceId,
  }) : _api = JellyfinApi(dio, baseUrl: baseUrl),
       _baseUrl = baseUrl;

  static const _defaultImageSize = 420;
  static const _sizeParams = {'fillHeight', 'fillWidth'};

  @override
  MediaServerCapabilities get capabilities => const MediaServerCapabilities();

  final JellyfinApi _api;
  final String _baseUrl;
  final String userId;
  final String token;
  final String deviceId;

  @override
  Future<LibraryPage> getAlbums(LibraryQuery query) async {
    final response = await _api.getAlbums(
      userId: userId,
      libraryId: query.libraryId,
      startIndex: '${query.startIndex}',
      limit: '${query.limit}',
      sortBy: mediaBrowserSort(query.sort),
      contributingArtistIds: query.appearsOnArtistId,
      sortOrder: mediaBrowserSortOrder(query.direction),
      artistIds: query.artistIds,
      genreIds: query.genreIds,
      filters: mediaBrowserFilters(query.filters),
      ids: query.ids,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getArtists(LibraryQuery query) async {
    final response = await _api.getArtists(
      userId: userId,
      startIndex: '${query.startIndex}',
      limit: '${query.limit}',
      sortBy: mediaBrowserSort(query.sort, target: ItemKind.artist),
      sortOrder: mediaBrowserSortOrder(query.direction),
      filters: mediaBrowserFilters(query.filters),
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getGenres(LibraryQuery query) async {
    final response = await _api.getGenres(
      userId: userId,
      libraryId: query.libraryId,
      startIndex: '${query.startIndex}',
      limit: '${query.limit}',
      sortBy: mediaBrowserSort(query.sort, target: ItemKind.genre),
      sortOrder: mediaBrowserSortOrder(query.direction),
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getPlaylists(LibraryQuery query) async {
    final response = await _api.getPlaylists(
      userId: userId,
      startIndex: '${query.startIndex}',
      limit: '${query.limit}',
      sortBy: mediaBrowserSort(query.sort, target: ItemKind.playlist),
      contributingArtistIds: query.appearsOnArtistId,
      sortOrder: mediaBrowserSortOrder(query.direction),
      artistIds: query.artistIds,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getAllSongs(LibraryQuery query) async {
    final response = await _api.getAllSongs(
      userId: userId,
      libraryId: query.libraryId,
      startIndex: '${query.startIndex}',
      limit: '${query.limit}',
      sortBy: mediaBrowserSort(query.sort, target: ItemKind.song),
      sortOrder: mediaBrowserSortOrder(query.direction),
      filters: mediaBrowserFilters(query.filters),
      fields: mediaBrowserFields(query.fields),
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getSongs(String albumId) async {
    final response = await _api.getSongs(userId: userId, albumId: albumId);
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getSongsOfSet(LibraryQuery query) async {
    final response = await _api.getSongsOfSet(
      userId: userId,
      libraryId: query.libraryId,
      artistIds: query.artistIds,
      genreIds: query.genreIds,
      filters: mediaBrowserFilters(query.filters),
      sortBy: mediaBrowserSort(query.sort, target: ItemKind.song),
      sortOrder: mediaBrowserSortOrder(query.direction),
      startIndex: '${query.startIndex}',
      limit: '${query.limit}',
      fields: mediaBrowserFields(query.fields),
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getPlaylistSongs(String playlistId) async {
    final response = await _api.getPlaylistSongs(
      playlistId: playlistId,
      userId: userId,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getSimilarAlbums(String albumId, {int limit = 12}) async {
    final response = await _api.getSimilarAlbums(
      albumId: albumId,
      userId: userId,
      limit: '$limit',
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<List<GeneratedPlaylist>> generateTodaysPlaylists({
    String? libraryId,
    bool includeDiscovery = false,
  }) => generateJellyfinTodaysPlaylists(
    this,
    libraryId: libraryId,
    includeDiscovery: includeDiscovery,
  );

  @override
  Future<List<LibraryItem>> getGeneratedPlaylistSongs({
    required String playlistId,
    String? libraryId,
  }) => fetchJellyfinGeneratedPlaylistSongs(
    this,
    playlistId: playlistId,
    libraryId: libraryId,
  );

  @override
  Future<LibraryPage> getLibraries() async {
    final response = await _api.getLibraries(userId: userId);
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryItem> getItem(String itemId, {required ItemKind kind}) async {
    final response = await _api.getItem(itemId: itemId);
    return response.data.toLibraryItem();
  }

  @override
  Future<LibraryPage> searchAlbums(SearchQuery query) async {
    final response = await _api.searchAlbums(
      userId: userId,
      searchTerm: query.term,
      libraryId: query.libraryId,
      startIndex: '${query.startIndex}',
      limit: '${query.limit}',
      sortOrder: mediaBrowserSortOrder(query.direction),
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> searchArtists(SearchQuery query) async {
    final response = await _api.searchArtists(
      userId: userId,
      searchTerm: query.term,
      startIndex: '${query.startIndex}',
      limit: '${query.limit}',
      sortOrder: mediaBrowserSortOrder(query.direction),
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> searchSongs(SearchQuery query) async {
    final response = await _api.searchSongs(
      userId: userId,
      searchTerm: query.term,
      libraryId: query.libraryId,
      startIndex: '${query.startIndex}',
      limit: '${query.limit}',
      sortOrder: mediaBrowserSortOrder(query.direction),
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> searchPlaylists(SearchQuery query) async {
    final response = await _api.searchPlaylists(
      userId: userId,
      libraryId: query.libraryId ?? '',
      searchTerm: query.term,
      startIndex: '${query.startIndex}',
      limit: '${query.limit}',
      sortOrder: mediaBrowserSortOrder(query.direction),
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<void> setFavorite(String itemId, {required bool favorite}) async {
    if (favorite) {
      await _api.saveFavorite(userId: userId, itemId: itemId);
    } else {
      await _api.removeFavorite(userId: userId, itemId: itemId);
    }
  }

  @override
  Future<void> createPlaylist(PlaylistData values) async {
    await _api.createPlaylist(values: values);
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _api.deletePlaylist(playlistId: playlistId);
  }

  @override
  Future<void> addPlaylistItems({
    required String playlistId,
    required List<String> itemIds,
  }) async {
    await _api.addPlaylistItems(
      playlistId: playlistId,
      userId: userId,
      entryIds: itemIds.join(','),
    );
  }

  @override
  Future<void> removePlaylistItem({
    required String playlistId,
    required String entryId,
  }) async {
    await _api.removePlaylistItem(playlistId: playlistId, entryIds: entryId);
  }

  @override
  Future<Lyrics?> getLyrics(String itemId) async {
    try {
      final response = await _api.getLyrics(itemId: itemId);
      return response.data.toLyrics();
    } on DioException catch (e) {
      if (MediaServerException.fromDio(e).isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<StreamSource> resolveStreamSource(
    LibraryItem song, {
    required String playSessionId,
    required StreamTargetProfile target,
  }) async {
    final audioSource = song.audioSources.firstOrNull;

    final profile = AudioStreamProfile.forSource(
      target: target,
      sourceContainer: audioSource?.container,
      sourceCodec: audioSource?.codec,
    );

    final useHls = profile.useHls;

    final uri = _resolve(
      useHls ? 'Audio/${song.id}/main.m3u8' : 'Audio/${song.id}/universal',
      {
        'UserId': userId,
        'ApiKey': token,
        'DeviceId': deviceId,
        'PlaySessionId': playSessionId,
        'MediaSourceId': audioSource?.id ?? song.id,
        'AudioCodec': profile.transcodingAudioCodec,
        if (useHls) ...{
          'SegmentContainer': profile.hlsSegmentContainer,
          'TranscodeReasons': 'AudioCodecNotSupported',
        } else ...{
          'TranscodingProtocol': 'http',
          'TranscodingContainer': profile.transcodingContainer,
          'Container': profile.directPlayContainers,
        },
      },
    );

    return StreamSource(
      uri: uri,
      isHls: useHls,
      outputContainer: profile.outputContainer,
      mimeType: profile.outputMimeType,
      requiresTranscode: profile.requiresTranscode,
    );
  }

  @override
  Uri? imageUri(
    LibraryItem item, {
    ImageKind kind = ImageKind.primary,
    int? size,
  }) {
    final ref = ItemImageRef.resolve(item, kind);
    if (ref == null) return null;

    final imageType = kind == ImageKind.backdrop ? 'Backdrop' : 'Primary';
    final pixels = size ?? _defaultImageSize;
    return _resolve('Items/${ref.id}/Images/$imageType', {
      'fillHeight': '$pixels',
      'fillWidth': '$pixels',
      'quality': '96',
      'tag': ref.tag,
    });
  }

  @override
  Uri resizedImageUri(Uri uri, int size) {
    final params = uri.queryParameters;
    if (params.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        for (final entry in params.entries)
          entry.key: _sizeParams.contains(entry.key) ? '$size' : entry.value,
      },
    );
  }

  Uri _resolve(String path, Map<String, String> queryParameters) {
    final base = Uri.parse(_baseUrl);
    final prefix = base.path.replaceAll(RegExp(r'/+$'), '');
    return base.replace(
      path: '$prefix/$path',
      queryParameters: queryParameters,
    );
  }

  @override
  Future<void> reportPlaybackStarted(PlaybackReport report) async {
    await _api.playbackStarted(values: _toPlaystateData(report));
  }

  @override
  Future<void> reportPlaybackProgress(PlaybackReport report) async {
    await _api.playbackProgress(values: _toPlaystateData(report));
  }

  @override
  Future<void> reportPlaybackStopped(PlaybackReport report) async {
    await _api.playbackStopped(values: _toPlaystateData(report));
  }

  PlaystateData _toPlaystateData(PlaybackReport report) => PlaystateData(
    playSessionId: report.playSessionId,
    itemId: report.itemId,
    mediaSourceId: report.mediaSourceId,
    positionTicks: report.position != null
        ? report.position!.inMilliseconds * 10000
        : null,
    isPaused: report.isPaused,
    canSeek: report.canSeek,
    nowPlayingQueue: report.queueItemIds.isEmpty
        ? null
        : [for (final id in report.queueItemIds) QueueItemData(id: id)],
  );

  @override
  Future<SessionStatus> validateSession() async {
    try {
      await _api.getArtists(userId: userId, limit: '1');
      return SessionStatus.valid;
    } on DioException catch (e) {
      if (MediaServerException.fromDio(e).isUnauthorized) {
        return SessionStatus.invalid;
      }
      return SessionStatus.unreachable;
    } on Object {
      return SessionStatus.unreachable;
    }
  }

  @override
  Future<void> signOut() async {
    await _api.signOut();
  }
}
