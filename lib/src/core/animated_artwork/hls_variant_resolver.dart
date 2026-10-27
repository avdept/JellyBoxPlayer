import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/animated_artwork/hls_variant.dart';

class HlsVariantResolver {
  HlsVariantResolver({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
              sendTimeout: _timeout,
              responseType: ResponseType.plain,
            ),
          );

  static const _timeout = Duration(seconds: 10);
  static const _cacheLimit = 64;

  final Dio _dio;
  final _resolved = <String, Uri>{};

  Future<Uri> resolve(Uri url, {required int targetWidth}) async {
    if (!_looksLikePlaylist(url)) return url;
    final key = '$url\n$targetWidth';
    final cached = _resolved[key];
    if (cached != null) return cached;

    try {
      final response = await _dio.getUri<String>(url);
      final body = response.data;
      if (body == null || body.isEmpty) return url;
      final variant = pickHlsVariant(
        parseHlsVariants(body, base: url),
        targetWidth: targetWidth,
      );
      if (variant == null) return url;
      if (_resolved.length >= _cacheLimit) _resolved.clear();
      return _resolved[key] = variant.url;
    } on Object catch (error) {
      debugPrint('[AnimatedCover] variant lookup failed for $url: $error');
      return url;
    }
  }

  static bool _looksLikePlaylist(Uri url) =>
      url.path.toLowerCase().endsWith('.m3u8');
}
