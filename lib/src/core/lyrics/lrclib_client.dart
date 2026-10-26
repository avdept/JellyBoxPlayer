import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LrclibTrack {
  const LrclibTrack({
    required this.id,
    this.trackName = '',
    this.artistName = '',
    this.albumName = '',
    this.duration,
    this.instrumental = false,
    this.plainLyrics,
    this.syncedLyrics,
  });

  factory LrclibTrack.fromJson(Map<String, dynamic> json) => LrclibTrack(
    id: (json['id'] as num?)?.toInt() ?? 0,
    trackName: json['trackName'] as String? ?? '',
    artistName: json['artistName'] as String? ?? '',
    albumName: json['albumName'] as String? ?? '',
    duration: switch (json['duration']) {
      final num seconds => Duration(milliseconds: (seconds * 1000).round()),
      _ => null,
    },
    instrumental: json['instrumental'] == true,
    plainLyrics: json['plainLyrics'] as String?,
    syncedLyrics: json['syncedLyrics'] as String?,
  );

  final int id;
  final String trackName;
  final String artistName;
  final String albumName;
  final Duration? duration;
  final bool instrumental;
  final String? plainLyrics;
  final String? syncedLyrics;

  bool get hasSynced => syncedLyrics?.trim().isNotEmpty ?? false;

  bool get hasPlain => plainLyrics?.trim().isNotEmpty ?? false;
}

class LrclibClient {
  LrclibClient({String baseUrl = defaultBaseUrl, String? userAgent})
    : _baseUrl = baseUrl,
      _dio = Dio(
        BaseOptions(
          connectTimeout: _timeout,
          receiveTimeout: _timeout,
          sendTimeout: _timeout,
          headers: {'User-Agent': ?userAgent},
        ),
      );

  static const defaultBaseUrl = 'https://lrclib.net';
  static const _timeout = Duration(seconds: 15);

  final String _baseUrl;
  final Dio _dio;

  @visibleForTesting
  Dio get dio => _dio;

  Future<LrclibTrack?> find({
    required String trackName,
    required String artistName,
    required String albumName,
    required Duration duration,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/get',
        queryParameters: {
          'track_name': trackName,
          'artist_name': artistName,
          'album_name': albumName,
          'duration': duration.inSeconds,
        },
      );
      final data = response.data;
      return data == null ? null : LrclibTrack.fromJson(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<LrclibTrack>> search({
    required String trackName,
    String? artistName,
    String? albumName,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_baseUrl/api/search',
      queryParameters: {
        'track_name': trackName,
        if (artistName != null && artistName.isNotEmpty)
          'artist_name': artistName,
        if (albumName != null && albumName.isNotEmpty) 'album_name': albumName,
      },
    );
    return [
      for (final item in response.data ?? const <dynamic>[])
        if (item is Map<String, dynamic>) LrclibTrack.fromJson(item),
    ];
  }
}
