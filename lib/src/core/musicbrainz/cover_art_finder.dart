import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_payload.dart';
import 'package:jplayer/src/core/musicbrainz/musicbrainz_client.dart';
import 'package:jplayer/src/domain/models/models.dart';

class CoverArtException implements Exception {
  const CoverArtException(this.message);

  final String message;

  @override
  String toString() => 'CoverArtException: $message';
}

@immutable
class CoverArtQuery {
  const CoverArtQuery({
    this.releaseId,
    this.releaseGroupId,
    this.artist,
    this.album,
  });

  static CoverArtQuery? forSong(LibraryItem song, {LibraryItem? album}) {
    final own = album != null && _owns(album, song) ? album : null;
    String? idFor(String key) => musicBrainzIds(
      song.externalIds[key] ?? own?.externalIds[key],
    ).firstOrNull;

    final query = CoverArtQuery(
      releaseId: idFor(ExternalIdProvider.musicBrainzAlbum),
      releaseGroupId: idFor(ExternalIdProvider.musicBrainzReleaseGroup),
      artist:
          _presence(song.albumArtist ?? own?.albumArtist) ??
          _presence(song.artistLabel),
      album: _presence(song.albumName ?? own?.name),
    );
    return query.key == null ? null : query;
  }

  final String? releaseId;
  final String? releaseGroupId;
  final String? artist;
  final String? album;

  String? get key {
    if (releaseId case final id?) return 'release/$id';
    if (releaseGroupId case final id?) return 'release-group/$id';
    if ((artist, album) case (final artist?, final album?)) {
      return 'name/${foldTitle(artist)}/${foldTitle(album)}';
    }
    return null;
  }

  static bool _owns(LibraryItem album, LibraryItem song) =>
      album.kind == ItemKind.album &&
      (song.albumId == null || song.albumId == album.id);

  static String? _presence(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

String foldTitle(String value) =>
    value.toLowerCase().replaceAll(_nonWord, ' ').trim();

class CoverArtFinder {
  CoverArtFinder({
    required MusicBrainzClient musicBrainz,
    required String userAgent,
    String baseUrl = defaultBaseUrl,
    Dio? dio,
  }) : _musicBrainz = musicBrainz,
       _baseUrl = baseUrl,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: _timeout,
               receiveTimeout: _timeout,
               sendTimeout: _timeout,
               headers: {'User-Agent': userAgent},
               followRedirects: false,
               validateStatus: (_) => true,
             ),
           );

  static const defaultBaseUrl = 'https://coverartarchive.org';
  static const _timeout = Duration(seconds: 15);
  static const _size = 500;

  final MusicBrainzClient _musicBrainz;
  final String _baseUrl;
  final Dio _dio;

  @visibleForTesting
  Dio get dio => _dio;

  Future<String?> find(CoverArtQuery query) async {
    if (query.releaseId case final id?) {
      final cover = await _front('release', id);
      if (cover != null) return cover;
    }
    if (query.releaseGroupId case final id?) {
      return _front('release-group', id);
    }

    final artist = query.artist;
    final album = query.album;
    if (artist == null || album == null) return null;

    final wanted = foldTitle(album);
    final groups = await _musicBrainz.searchReleaseGroups(
      artist: artist,
      album: album,
    );
    for (final group in groups) {
      final id = musicBrainzIds(group.id).firstOrNull;
      if (id != null && foldTitle(group.title) == wanted) {
        return _front('release-group', id);
      }
    }
    return null;
  }

  Future<String?> _front(String entity, String id) async {
    final url = '$_baseUrl/$entity/$id/front-$_size';
    final Response<Object?> response;
    try {
      response = await _dio.head<Object?>(url);
    } on DioException catch (error) {
      throw CoverArtException(error.message ?? error.type.name);
    }
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 400) return url;
    if (status == 400 || status == 404) return null;
    throw CoverArtException('HTTP $status');
  }
}
