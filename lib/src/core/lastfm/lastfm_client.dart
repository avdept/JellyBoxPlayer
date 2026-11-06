import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';

abstract final class LastFmErrorCode {
  static const authenticationFailed = 4;
  static const invalidParameters = 6;
  static const invalidSessionKey = 9;
  static const invalidApiKey = 10;
  static const serviceOffline = 11;
  static const invalidSignature = 13;
  static const tokenNotAuthorized = 14;
  static const tokenExpired = 15;
  static const temporaryError = 16;
  static const suspendedApiKey = 26;
  static const rateLimitExceeded = 29;
}

ScrobbleFailure lastFmFailure(int code) => switch (code) {
  LastFmErrorCode.authenticationFailed ||
  LastFmErrorCode.invalidSessionKey ||
  LastFmErrorCode.tokenNotAuthorized ||
  LastFmErrorCode.tokenExpired => ScrobbleFailure.unauthorized,
  LastFmErrorCode.rateLimitExceeded => ScrobbleFailure.rateLimited,
  2 || 3 || 5 || 6 || 7 => ScrobbleFailure.rejected,
  _ => ScrobbleFailure.unavailable,
};

class LastFmException extends ScrobbleException {
  LastFmException(this.code, String message)
    : super(message, failure: lastFmFailure(code));

  final int code;

  bool get tokenNotAuthorized => code == LastFmErrorCode.tokenNotAuthorized;

  bool get badCredentials => switch (code) {
    LastFmErrorCode.invalidApiKey ||
    LastFmErrorCode.invalidSignature ||
    LastFmErrorCode.suspendedApiKey => true,
    _ => false,
  };

  @override
  String toString() => 'LastFmException($code ${failure.name}): $message';
}

@immutable
class LastFmCredentials {
  const LastFmCredentials({required this.apiKey, required this.apiSecret});

  final String apiKey;
  final String apiSecret;

  @override
  bool operator ==(Object other) =>
      other is LastFmCredentials &&
      other.apiKey == apiKey &&
      other.apiSecret == apiSecret;

  @override
  int get hashCode => Object.hash(apiKey, apiSecret);
}

@immutable
class LastFmSession {
  const LastFmSession({required this.userName, required this.key});

  final String userName;
  final String key;
}

class LastFmClient {
  LastFmClient();

  static const apiUrl = 'https://ws.audioscrobbler.com/2.0/';
  static final Uri apiAccountUri = Uri.parse(
    'https://www.last.fm/api/account/create',
  );
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

  static Uri authorizationUrl(LastFmCredentials credentials, String token) =>
      Uri.https('www.last.fm', '/api/auth/', {
        'api_key': credentials.apiKey,
        'token': token,
      });

  Future<String> getToken(LastFmCredentials credentials) async {
    final data = await _call(
      credentials,
      'auth.getToken',
      const {},
      post: false,
    );
    if (data['token'] case final String token when token.isNotEmpty) {
      return token;
    }
    throw const ScrobbleException('Last.fm did not return a token');
  }

  Future<LastFmSession> getSession(
    LastFmCredentials credentials,
    String token,
  ) async {
    final data = await _call(credentials, 'auth.getSession', {
      'token': token,
    }, post: false);
    if (data['session'] case {
      'name': final String name,
      'key': final String key,
    } when key.isNotEmpty) {
      return LastFmSession(userName: name, key: key);
    }
    throw const ScrobbleException('Last.fm did not return a session');
  }

  Future<void> updateNowPlaying(
    LastFmCredentials credentials,
    Map<String, String> track, {
    required String sessionKey,
  }) => _call(credentials, 'track.updateNowPlaying', {
    ...track,
    'sk': sessionKey,
  });

  Future<int> scrobble(
    LastFmCredentials credentials,
    Map<String, String> tracks, {
    required String sessionKey,
  }) async {
    final data = await _call(credentials, 'track.scrobble', {
      ...tracks,
      'sk': sessionKey,
    });
    return ignoredScrobbles(data);
  }

  static int ignoredScrobbles(Map<String, Object?> data) {
    if (data['scrobbles'] case {'@attr': {'ignored': final Object ignored}}) {
      return int.tryParse(ignored.toString()) ?? 0;
    }
    return 0;
  }

  @visibleForTesting
  static Map<String, String> sign(
    LastFmCredentials credentials,
    String method,
    Map<String, String> params,
  ) {
    final signed = {
      ...params,
      'method': method,
      'api_key': credentials.apiKey,
    };
    final keys = signed.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in keys) {
      buffer
        ..write(key)
        ..write(signed[key]);
    }
    buffer.write(credentials.apiSecret);
    signed['api_sig'] = md5.convert(utf8.encode(buffer.toString())).toString();
    return signed..['format'] = 'json';
  }

  Future<Map<String, Object?>> _call(
    LastFmCredentials credentials,
    String method,
    Map<String, String> params, {
    bool post = true,
  }) async {
    final request = sign(credentials, method, params);
    final Response<Object?> response;
    try {
      response = post
          ? await _dio.post<Object?>(
              apiUrl,
              data: request,
              options: Options(contentType: Headers.formUrlEncodedContentType),
            )
          : await _dio.get<Object?>(apiUrl, queryParameters: request);
    } on DioException catch (error) {
      final body = error.response?.data;
      if (body is Map && body['error'] != null) throw _failure(body);
      throw ScrobbleException.fromStatus(
        error.response?.statusCode,
        error.message ?? 'Request failed',
        retryAfter: _retryAfter(error.response),
      );
    }
    final body = response.data;
    if (body is! Map) {
      throw const ScrobbleException('Last.fm returned an unexpected response');
    }
    if (body['error'] != null) throw _failure(body);
    return body.cast<String, Object?>();
  }

  static LastFmException _failure(Map<Object?, Object?> body) {
    final code = int.tryParse(body['error'].toString()) ?? 0;
    return LastFmException(
      code,
      body['message']?.toString() ?? 'Last.fm error $code',
    );
  }

  static Duration? _retryAfter(Response<Object?>? response) {
    final seconds = int.tryParse(response?.headers.value('retry-after') ?? '');
    return seconds != null && seconds > 0 ? Duration(seconds: seconds) : null;
  }
}
