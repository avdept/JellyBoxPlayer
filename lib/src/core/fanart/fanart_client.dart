import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:optional_features/catalog.dart';

enum FanartFailure { badKey, notFound, unavailable }

class FanartException implements Exception {
  const FanartException(this.failure, this.message, {this.statusCode});

  final FanartFailure failure;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'FanartException: $message';
}

@immutable
class FanartCredentials {
  const FanartCredentials({this.apiKey = '', this.clientKey = ''});

  static const none = FanartCredentials();

  final String apiKey;
  final String clientKey;

  bool get hasOwnKey => apiKey.isNotEmpty;

  bool get hasPersonalKey => clientKey.isNotEmpty;

  bool get isEmpty => !hasOwnKey && !hasPersonalKey;

  @override
  bool operator ==(Object other) =>
      other is FanartCredentials &&
      other.apiKey == apiKey &&
      other.clientKey == clientKey;

  @override
  int get hashCode => Object.hash(apiKey, clientKey);
}

@immutable
class FanartImage {
  const FanartImage({required this.id, required this.url, this.likes = 0});

  factory FanartImage.fromJson(Map<String, dynamic> json) => FanartImage(
    id: '${json['id'] ?? ''}',
    url: json['url'] as String? ?? '',
    likes: int.tryParse('${json['likes'] ?? ''}') ?? 0,
  );

  final String id;
  final String url;
  final int likes;

  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'likes': '$likes'};

  Uri get uri => Uri.parse(url);
}

@immutable
class FanartArtistImages {
  const FanartArtistImages({this.backgrounds = const []});

  factory FanartArtistImages.fromJson(Map<String, dynamic> json) =>
      FanartArtistImages(backgrounds: _images(json['artistbackground']));

  static const empty = FanartArtistImages();

  final List<FanartImage> backgrounds;

  bool get isEmpty => backgrounds.isEmpty;

  Map<String, dynamic> toJson() => {
    'artistbackground': [for (final image in backgrounds) image.toJson()],
  };

  static List<FanartImage> _images(Object? value) =>
      [
          for (final item in value as List<dynamic>? ?? const [])
            if (item is Map<String, dynamic>) FanartImage.fromJson(item),
        ]
        ..removeWhere((image) => image.url.isEmpty)
        ..sort((a, b) => b.likes.compareTo(a.likes));
}

class FanartClient {
  FanartClient({
    required String userAgent,
    required String linkUrl,
    String baseUrl = defaultBaseUrl,
    Dio? dio,
    CatalogCacheStore? cache,
    DateTime Function()? now,
  }) : _baseUrl = baseUrl,
       _linkUrl = linkUrl,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: _timeout,
               receiveTimeout: _timeout,
               sendTimeout: _timeout,
               headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
               validateStatus: (_) => true,
             ),
           ),
       _store = cache,
       _now = now ?? DateTime.now;

  static const sourceId = 'fanart';
  static const defaultBaseUrl = 'https://webservice.fanart.tv/v3.2';
  static const linkPath = '/integrations/fanart';
  static const imagesLifetime = Duration(days: 7);
  static const noImagesLifetime = Duration(days: 1);
  static const validationArtistId = 'b10bbbfc-cf9e-42e0-be17-e2c3e1d2600d';
  static final Uri apiKeyUri = Uri.parse('https://fanart.tv/get-an-api-key/');
  static const _timeout = Duration(seconds: 15);

  final String _baseUrl;
  final String _linkUrl;
  final Dio _dio;
  final CatalogCacheStore? _store;
  final DateTime Function() _now;

  @visibleForTesting
  Dio get dio => _dio;

  Future<FanartArtistImages> artist(
    String musicBrainzId,
    FanartCredentials credentials,
  ) async {
    final key = 'music/$musicBrainzId';
    final stored = await _readStore(key);
    if (stored != null && stored.expires.isAfter(_now())) {
      return _decode(stored.json);
    }

    var images = FanartArtistImages.empty;
    try {
      images = FanartArtistImages.fromJson(
        await _get('/music/$musicBrainzId', credentials),
      );
    } on FanartException catch (error) {
      if (error.failure != FanartFailure.notFound) {
        if (stored == null || error.failure == FanartFailure.badKey) rethrow;
        return _decode(stored.json);
      }
    }
    await _writeStore(
      key,
      jsonEncode(images.toJson()),
      images.isEmpty ? noImagesLifetime : imagesLifetime,
    );
    return images;
  }

  Future<void> validate(FanartCredentials credentials) =>
      _get('/music/$validationArtistId', credentials);

  Future<Map<String, dynamic>> _get(
    String path,
    FanartCredentials credentials,
  ) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        credentials.hasOwnKey ? '$_baseUrl$path' : '$_linkUrl$linkPath$path',
        queryParameters: {
          if (credentials.hasOwnKey) 'api_key': credentials.apiKey,
          if (credentials.hasPersonalKey) 'client_key': credentials.clientKey,
        },
      );
    } on DioException catch (error) {
      throw FanartException(
        FanartFailure.unavailable,
        error.message ?? error.type.name,
      );
    }
    final status = response.statusCode ?? 0;
    final body = response.data;
    if (status == 200 && body != null && body['status'] != 'error') return body;
    final message = body?['error message'] as String? ?? 'HTTP $status';
    throw FanartException(
      switch (status) {
        401 || 403 => FanartFailure.badKey,
        404 => FanartFailure.notFound,
        _ => FanartFailure.unavailable,
      },
      message,
      statusCode: status,
    );
  }

  static FanartArtistImages _decode(String json) =>
      FanartArtistImages.fromJson(jsonDecode(json) as Map<String, dynamic>);

  Future<CatalogCacheEntry?> _readStore(String key) async {
    try {
      return await _store?.read(sourceId, key);
    } on Object {
      return null;
    }
  }

  Future<void> _writeStore(String key, String json, Duration lifetime) async {
    try {
      await _store?.write(sourceId, key, json, expires: _now().add(lifetime));
    } on Object {
      return;
    }
  }
}
