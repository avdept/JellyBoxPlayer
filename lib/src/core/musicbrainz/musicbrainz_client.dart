import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/musicbrainz/barcode_match.dart';
import 'package:jplayer/src/core/musicbrainz/musicbrainz_models.dart';
import 'package:optional_features/catalog.dart';

class MusicBrainzException implements Exception {
  const MusicBrainzException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'MusicBrainzException: $message';
}

class MusicBrainzClient {
  MusicBrainzClient({
    required String userAgent,
    String baseUrl = defaultBaseUrl,
    Dio? dio,
    CatalogCacheStore? cache,
    DateTime Function()? now,
    Future<void> Function(Duration)? wait,
  }) : _baseUrl = baseUrl,
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
       _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  static const sourceId = 'musicbrainz';
  static const defaultBaseUrl = 'https://musicbrainz.org/ws/2';
  static const minInterval = Duration(milliseconds: 1100);
  static const barcodeLifetime = Duration(days: 30);
  static const noMatchLifetime = Duration(hours: 1);
  static const _timeout = Duration(seconds: 15);
  static const _retries = 3;
  static const _searchLimit = 100;

  final String _baseUrl;
  final Dio _dio;
  final CatalogCacheStore? _store;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;
  DateTime? _lastRequest;
  var _queue = Future<void>.value();

  @visibleForTesting
  Dio get dio => _dio;

  Future<List<MusicBrainzRelease>> releasesByBarcode(String barcode) async {
    final normalized = normalizeBarcode(barcode);
    if (normalized == null) return const [];
    final key = 'release/barcode/$normalized';

    final stored = await _readStore(key);
    if (stored != null && stored.expires.isAfter(_now())) {
      return _decode(stored.json);
    }

    final List<MusicBrainzRelease> releases;
    try {
      final json = await _get('/release', {
        'query': 'barcode:"$normalized"',
        'limit': '$_searchLimit',
      });
      releases = MusicBrainzReleaseSearch.fromJson(json).releases;
      await _writeStore(
        key,
        jsonEncode(json['releases'] ?? const []),
        releases.isEmpty ? noMatchLifetime : barcodeLifetime,
      );
    } on MusicBrainzException {
      if (stored == null) rethrow;
      return _decode(stored.json);
    }
    return releases;
  }

  Future<MusicBrainzReleaseMatch?> resolveBarcode(
    String barcode, {
    String? artistName,
  }) async {
    final releases = await releasesByBarcode(barcode);
    return pickReleaseMatch(releases, barcode: barcode, artistName: artistName);
  }

  static List<MusicBrainzRelease> _decode(String json) => [
    for (final release in jsonDecode(json) as List<dynamic>)
      MusicBrainzRelease.fromJson(release as Map<String, dynamic>),
  ];

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    for (var attempt = 0; ; attempt++) {
      await _throttle();
      final Response<Map<String, dynamic>> response;
      try {
        response = await _dio.get<Map<String, dynamic>>(
          '$_baseUrl$path',
          queryParameters: {...query, 'fmt': 'json'},
        );
      } on DioException catch (error) {
        throw MusicBrainzException(error.message ?? error.type.name);
      }
      final status = response.statusCode ?? 0;
      final body = response.data;
      if (status == 200 && body != null && body['error'] == null) return body;

      final message = body?['error'] as String? ?? 'HTTP $status';
      if (status == 503 && attempt < _retries) {
        await _wait(_backoff(response, attempt));
        continue;
      }
      throw MusicBrainzException(message, statusCode: status);
    }
  }

  Duration _backoff(Response<Object?> response, int attempt) {
    final header = response.headers.value('retry-after');
    final seconds = int.tryParse(header ?? '') ?? 0;
    if (seconds > 0) return Duration(seconds: seconds);
    return Duration(seconds: 1 << attempt);
  }

  Future<void> _throttle() {
    final turn = _queue.then((_) async {
      final last = _lastRequest;
      if (last != null) {
        final since = _now().difference(last);
        if (since < minInterval) await _wait(minInterval - since);
      }
      _lastRequest = _now();
    });
    _queue = turn.then((_) {}, onError: (Object _) {});
    return turn;
  }

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
