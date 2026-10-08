import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AnimatedArtwork {
  const AnimatedArtwork({required this.url, this.tallUrl});

  final Uri url;
  final Uri? tallUrl;
}

class AnimatedArtworkClient {
  AnimatedArtworkClient({Dio? dio, this.baseUrl = defaultBaseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
              sendTimeout: _timeout,
            ),
          );

  static const defaultBaseUrl = 'https://artwork.m8tec.top';
  static const _timeout = Duration(seconds: 30);

  final String baseUrl;
  final Dio _dio;

  @visibleForTesting
  Dio get dio => _dio;

  Future<AnimatedArtwork?> search({
    required String artist,
    required String album,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/api/v1/artwork/search',
        queryParameters: {'artist': artist, 'album': album},
      );
      return _parse(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  static AnimatedArtwork? _parse(Map<String, dynamic>? data) {
    final url = _uri(data?['url']);
    if (url == null) return null;
    return AnimatedArtwork(url: url, tallUrl: _uri(data?['url_tall']));
  }

  static Uri? _uri(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return null;
    return uri;
  }
}
