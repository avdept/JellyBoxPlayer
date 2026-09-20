import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';

abstract final class ListenType {
  static const single = 'single';
  static const playingNow = 'playing_now';
  static const import = 'import';
}

class ListenBrainzClient {
  ListenBrainzClient();

  static const apiUrl = 'https://api.listenbrainz.org';
  static const _timeout = Duration(seconds: 15);

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
    ),
  );

  @visibleForTesting
  Dio get dio => _dio;

  Future<String> validateToken(String token) async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(
        '$apiUrl/1/validate-token',
        options: _options(token),
      ),
    );
    final data = response.data ?? const <String, dynamic>{};
    if (data['valid'] == true && data['user_name'] is String) {
      return data['user_name'] as String;
    }
    throw ScrobbleException.fromStatus(
      401,
      data['message']?.toString() ?? 'Invalid token',
    );
  }

  Future<void> submitListens({
    required String token,
    required String listenType,
    required List<Map<String, Object?>> payload,
  }) async {
    await _request(
      () => _dio.post<void>(
        '$apiUrl/1/submit-listens',
        data: {'listen_type': listenType, 'payload': payload},
        options: _options(token),
      ),
    );
  }

  Options _options(String token) => Options(
    headers: {
      'Authorization': 'Token $token',
      Headers.contentTypeHeader: Headers.jsonContentType,
    },
    responseType: ResponseType.json,
  );

  Future<Response<T>> _request<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      final response = error.response;
      final data = response?.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : (error.message ?? 'Request failed');
      throw ScrobbleException.fromStatus(
        response?.statusCode,
        message,
        retryAfter: _retryAfter(response),
      );
    }
  }

  static Duration? _retryAfter(Response<Object?>? response) {
    if (response == null) return null;
    for (final name in const ['x-ratelimit-reset-in', 'retry-after']) {
      final seconds = int.tryParse(response.headers.value(name) ?? '');
      if (seconds != null && seconds > 0) return Duration(seconds: seconds);
    }
    return null;
  }
}
