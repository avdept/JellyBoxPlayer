import 'package:dio/dio.dart';
import 'package:jplayer/src/core/audio/audio_stream_profile.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/backend/item_image_ref.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_playlist_generator.dart';
import 'package:jplayer/src/data/backend/mappers/item_dto_mapper.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/dto/dto.dart';
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

  final JellyfinApi _api;
  final String _baseUrl;
  final String userId;
  final String token;
  final String deviceId;

  @override
  Future<LibraryPage> getAlbums({
    required String userId,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'DateCreated,SortName',
    String? contributingArtistIds,
    String sortOrder = 'Descending',
    List<String> artistIds = const [],
    List<String> genreIds = const [],
    List<String> filters = const [],
    List<String> ids = const [],
  }) async {
    final response = await _api.getAlbums(
      userId: userId,
      libraryId: libraryId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      contributingArtistIds: contributingArtistIds,
      sortOrder: sortOrder,
      artistIds: artistIds,
      genreIds: genreIds,
      filters: filters,
      ids: ids,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getArtists({
    required String userId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'SortName',
    String sortOrder = 'Descending',
    List<String> filters = const [],
  }) async {
    final response = await _api.getArtists(
      userId: userId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
      filters: filters,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getGenres({
    required String userId,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
  }) async {
    final response = await _api.getGenres(
      userId: userId,
      libraryId: libraryId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getPlaylists({
    required String userId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'DateCreated,SortName',
    String? contributingArtistIds,
    String sortOrder = 'Descending',
    List<String> artistIds = const [],
  }) async {
    final response = await _api.getPlaylists(
      userId: userId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      contributingArtistIds: contributingArtistIds,
      sortOrder: sortOrder,
      artistIds: artistIds,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getAllSongs({
    required String userId,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    List<String> filters = const [],
    List<String> fields = const ['MediaSources'],
  }) async {
    final response = await _api.getAllSongs(
      userId: userId,
      libraryId: libraryId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
      filters: filters,
      fields: fields,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getSongs({
    required String userId,
    required String albumId,
  }) async {
    final response = await _api.getSongs(userId: userId, albumId: albumId);
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getSongsOfSet({
    required String userId,
    String? libraryId,
    List<String> artistIds = const [],
    List<String> genreIds = const [],
    List<String> filters = const [],
    String sortBy = 'AlbumArtist,Album,ParentIndexNumber,IndexNumber',
    String sortOrder = 'Ascending',
    String startIndex = '0',
    String limit = '300',
    List<String> fields = const ['MediaSources'],
  }) async {
    final response = await _api.getSongsOfSet(
      userId: userId,
      libraryId: libraryId,
      artistIds: artistIds,
      genreIds: genreIds,
      filters: filters,
      sortBy: sortBy,
      sortOrder: sortOrder,
      startIndex: startIndex,
      limit: limit,
      fields: fields,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getPlaylistSongs({
    required String userId,
    required String playlistId,
  }) async {
    final response = await _api.getPlaylistSongs(
      playlistId: playlistId,
      userId: userId,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> getSimilarAlbums({
    required String userId,
    required String albumId,
    String limit = '12',
  }) async {
    final response = await _api.getSimilarAlbums(
      albumId: albumId,
      userId: userId,
      limit: limit,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<List<GeneratedPlaylist>> generateTodaysPlaylists({
    required String userId,
    String? libraryId,
    bool includeDiscovery = false,
  }) => generateJellyfinTodaysPlaylists(
    this,
    userId: userId,
    libraryId: libraryId,
    includeDiscovery: includeDiscovery,
  );

  @override
  Future<List<LibraryItem>> getGeneratedPlaylistSongs({
    required String userId,
    required String playlistId,
    String? libraryId,
  }) => fetchJellyfinGeneratedPlaylistSongs(
    this,
    userId: userId,
    playlistId: playlistId,
    libraryId: libraryId,
  );

  @override
  Future<LibraryPage> getLibraries({required String userId}) async {
    final response = await _api.getLibraries(userId: userId);
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryItem> getItem(String itemId) async {
    final response = await _api.getItem(itemId: itemId);
    return response.data.toLibraryItem();
  }

  @override
  Future<LibraryPage> searchAlbums({
    required String userId,
    required String searchTerm,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  }) async {
    final response = await _api.searchAlbums(
      userId: userId,
      searchTerm: searchTerm,
      libraryId: libraryId,
      startIndex: startIndex,
      limit: limit,
      sortOrder: sortOrder,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> searchArtists({
    required String userId,
    required String searchTerm,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  }) async {
    final response = await _api.searchArtists(
      userId: userId,
      searchTerm: searchTerm,
      startIndex: startIndex,
      limit: limit,
      sortOrder: sortOrder,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> searchSongs({
    required String userId,
    required String searchTerm,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  }) async {
    final response = await _api.searchSongs(
      userId: userId,
      searchTerm: searchTerm,
      libraryId: libraryId,
      startIndex: startIndex,
      limit: limit,
      sortOrder: sortOrder,
    );
    return response.data.toLibraryPage();
  }

  @override
  Future<LibraryPage> searchPlaylists({
    required String userId,
    required String searchTerm,
    required String libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  }) async {
    final response = await _api.searchPlaylists(
      userId: userId,
      libraryId: libraryId,
      searchTerm: searchTerm,
      startIndex: startIndex,
      limit: limit,
      sortOrder: sortOrder,
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
  Future<LyricsDTO> getLyrics(String itemId) async {
    final response = await _api.getLyrics(itemId: itemId);
    return response.data;
  }

  @override
  Future<StreamSource> resolveStreamSource(
    LibraryItem song, {
    required String playSessionId,
    bool preferHls = true,
  }) async {
    final audioSource = song.audioSources.firstOrNull;

    final profile = AudioStreamProfile.forSource(
      sourceContainer: audioSource?.container,
      sourceCodec: audioSource?.codec,
    );

    final useHls = preferHls && profile.requiresTranscode;

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
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) return SessionStatus.invalid;
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
