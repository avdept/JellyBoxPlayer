import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_credentials.dart';
import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';

class SubsonicApi {
  SubsonicApi(this._dio, {required String baseUrl, this.credentials})
    : _baseUrl = baseUrl;

  static const apiVersion = '1.16.1';
  static const clientId = 'JellyBox';

  final Dio _dio;
  final String _baseUrl;
  final SubsonicCredentials? credentials;

  static Map<String, dynamic>? envelopeOf(Object? data) {
    var body = data;
    if (body is String) {
      try {
        body = jsonDecode(body);
      } on FormatException {
        return null;
      }
    }
    if (body is! Map) return null;
    final envelope = body[SubsonicEnvelopeDTO.key];
    return envelope is Map ? Map<String, dynamic>.from(envelope) : null;
  }

  Uri uri(String method, [Map<String, Object?> params = const {}]) {
    final base = Uri.parse(_baseUrl);
    final prefix = base.path.replaceAll(RegExp(r'/+$'), '');
    final query = <String, dynamic>{
      ...?credentials?.queryParameters,
      'v': apiVersion,
      'c': clientId,
      'f': 'json',
    };
    for (final entry in params.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is Iterable) {
        final values = [for (final item in value) '$item'];
        if (values.isNotEmpty) query[entry.key] = values;
      } else {
        query[entry.key] = '$value';
      }
    }
    return base.replace(path: '$prefix/rest/$method', queryParameters: query);
  }

  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, Object?> params = const {},
  ]) async {
    final response = await _dio.getUri<Object?>(
      uri(method, params),
      options: Options(responseType: ResponseType.json),
    );
    return envelopeOf(response.data) ?? const {};
  }

  Map<String, dynamic> _section(Map<String, dynamic> body, String key) {
    final section = body[key];
    return section is Map ? Map<String, dynamic>.from(section) : const {};
  }

  Future<SubsonicEnvelopeDTO> ping() async =>
      SubsonicEnvelopeDTO.fromJson(await call('ping'));

  Future<List<SubsonicExtensionDTO>> getOpenSubsonicExtensions() async =>
      SubsonicExtensionsDTO.fromJson(
        await call('getOpenSubsonicExtensions'),
      ).openSubsonicExtensions;

  Future<List<SubsonicMusicFolderDTO>> getMusicFolders() async =>
      SubsonicMusicFoldersDTO.fromJson(
        _section(await call('getMusicFolders'), 'musicFolders'),
      ).musicFolder;

  Future<List<SubsonicArtistDTO>> getArtists({String? musicFolderId}) async {
    final body = await call('getArtists', {'musicFolderId': musicFolderId});
    final indexes = SubsonicArtistsDTO.fromJson(_section(body, 'artists'));
    return [for (final index in indexes.index) ...index.artist];
  }

  Future<SubsonicArtistDTO> getArtist(String id) async =>
      SubsonicArtistDTO.fromJson(
        _section(await call('getArtist', {'id': id}), 'artist'),
      );

  Future<SubsonicAlbumDTO> getAlbum(String id) async =>
      SubsonicAlbumDTO.fromJson(
        _section(await call('getAlbum', {'id': id}), 'album'),
      );

  Future<SubsonicChildDTO> getSong(String id) async =>
      SubsonicChildDTO.fromJson(
        _section(await call('getSong', {'id': id}), 'song'),
      );

  Future<List<SubsonicGenreDTO>> getGenres() async =>
      SubsonicGenresDTO.fromJson(
        _section(await call('getGenres'), 'genres'),
      ).genre;

  Future<List<SubsonicAlbumDTO>> getAlbumList2({
    required String type,
    int size = 10,
    int offset = 0,
    String? genre,
    String? musicFolderId,
    int? fromYear,
    int? toYear,
  }) async {
    final body = await call('getAlbumList2', {
      'type': type,
      'size': size,
      'offset': offset,
      'genre': genre,
      'musicFolderId': musicFolderId,
      'fromYear': fromYear,
      'toYear': toYear,
    });
    return SubsonicAlbumListDTO.fromJson(_section(body, 'albumList2')).album;
  }

  Future<List<SubsonicChildDTO>> getRandomSongs({
    int size = 10,
    String? genre,
    String? musicFolderId,
  }) async {
    final body = await call('getRandomSongs', {
      'size': size,
      'genre': genre,
      'musicFolderId': musicFolderId,
    });
    return SubsonicSongListDTO.fromJson(_section(body, 'randomSongs')).song;
  }

  Future<List<SubsonicChildDTO>> getSongsByGenre({
    required String genre,
    int count = 10,
    int offset = 0,
    String? musicFolderId,
  }) async {
    final body = await call('getSongsByGenre', {
      'genre': genre,
      'count': count,
      'offset': offset,
      'musicFolderId': musicFolderId,
    });
    return SubsonicSongListDTO.fromJson(_section(body, 'songsByGenre')).song;
  }

  Future<SubsonicItemSetDTO> getStarred2({String? musicFolderId}) async =>
      SubsonicItemSetDTO.fromJson(
        _section(
          await call('getStarred2', {'musicFolderId': musicFolderId}),
          'starred2',
        ),
      );

  Future<SubsonicItemSetDTO> search3({
    required String query,
    int artistCount = 0,
    int artistOffset = 0,
    int albumCount = 0,
    int albumOffset = 0,
    int songCount = 0,
    int songOffset = 0,
    String? musicFolderId,
  }) async {
    final body = await call('search3', {
      'query': query,
      'artistCount': artistCount,
      'artistOffset': artistOffset,
      'albumCount': albumCount,
      'albumOffset': albumOffset,
      'songCount': songCount,
      'songOffset': songOffset,
      'musicFolderId': musicFolderId,
    });
    return SubsonicItemSetDTO.fromJson(_section(body, 'searchResult3'));
  }

  Future<List<SubsonicPlaylistDTO>> getPlaylists() async =>
      SubsonicPlaylistsDTO.fromJson(
        _section(await call('getPlaylists'), 'playlists'),
      ).playlist;

  Future<SubsonicPlaylistDTO> getPlaylist(String id) async =>
      SubsonicPlaylistDTO.fromJson(
        _section(await call('getPlaylist', {'id': id}), 'playlist'),
      );

  Future<SubsonicPlaylistDTO?> createPlaylist({required String name}) async {
    final body = await call('createPlaylist', {'name': name});
    final playlist = body['playlist'];
    if (playlist is! Map) return null;
    return SubsonicPlaylistDTO.fromJson(Map<String, dynamic>.from(playlist));
  }

  Future<void> updatePlaylist({
    required String playlistId,
    String? name,
    bool? public,
    List<String> songIdToAdd = const [],
    List<int> songIndexToRemove = const [],
  }) => call('updatePlaylist', {
    'playlistId': playlistId,
    'name': name,
    'public': public,
    'songIdToAdd': songIdToAdd,
    'songIndexToRemove': songIndexToRemove,
  });

  Future<void> deletePlaylist(String id) => call('deletePlaylist', {'id': id});

  Future<void> star(String id) => call('star', {'id': id});

  Future<void> unstar(String id) => call('unstar', {'id': id});

  Future<void> scrobble({
    required String id,
    required bool submission,
    DateTime? time,
  }) => call('scrobble', {
    'id': id,
    'submission': submission,
    'time': time?.toUtc().millisecondsSinceEpoch,
  });

  Future<void> reportPlayback({
    required String mediaId,
    required String state,
    Duration? position,
  }) => call('reportPlayback', {
    'mediaId': mediaId,
    'mediaType': 'song',
    'state': state,
    'positionMs': position?.inMilliseconds,
  });

  Future<SubsonicLyricsListDTO> getLyricsBySongId(String id) async =>
      SubsonicLyricsListDTO.fromJson(
        _section(await call('getLyricsBySongId', {'id': id}), 'lyricsList'),
      );

  Uri streamUri(
    String id, {
    String? format,
    int? maxBitRate,
    bool estimateContentLength = true,
  }) => uri('stream', {
    'id': id,
    'format': format,
    'maxBitRate': maxBitRate,
    'estimateContentLength': estimateContentLength,
  });

  Uri coverArtUri(String id, {int? size}) =>
      uri('getCoverArt', {'id': id, 'size': size});
}
