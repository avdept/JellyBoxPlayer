import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_client.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  late MockHttpClientAdapter adapter;
  late ListenBrainzClient client;

  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    client = ListenBrainzClient()..dio.httpClientAdapter = adapter;
  });

  void respond(
    int status,
    Object body, {
    Map<String, List<String>> headers = const {},
  }) {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          ...headers,
        },
      ),
    );
  }

  RequestOptions sentRequest() =>
      verify(() => adapter.fetch(captureAny(), any(), any())).captured.single
          as RequestOptions;

  test('validateToken returns the user name for a valid token', () async {
    respond(200, {'code': 200, 'valid': true, 'user_name': 'alex'});

    final name = await client.validateToken('secret');

    expect(name, 'alex');
    final request = sentRequest();
    expect(request.method, 'GET');
    expect(
      request.uri.toString(),
      'https://api.listenbrainz.org/1/validate-token',
    );
    expect(request.headers['Authorization'], 'Token secret');
  });

  test('validateToken rejects a token the server marks invalid', () async {
    respond(200, {'code': 200, 'valid': false, 'message': 'Invalid token.'});

    await expectLater(
      client.validateToken('bad'),
      throwsA(
        isA<ScrobbleException>().having(
          (e) => e.isUnauthorized,
          'isUnauthorized',
          isTrue,
        ),
      ),
    );
  });

  test('submitListens posts the listen type and payload as JSON', () async {
    respond(200, {'status': 'ok'});
    final listen = {
      'listened_at': 1,
      'track_metadata': {'artist_name': 'A', 'track_name': 'B'},
    };

    await client.submitListens(
      token: 'secret',
      listenType: ListenType.single,
      payload: [listen],
    );

    final request = sentRequest();
    expect(request.method, 'POST');
    expect(
      request.uri.toString(),
      'https://api.listenbrainz.org/1/submit-listens',
    );
    expect(request.headers['Authorization'], 'Token secret');
    expect(request.data, {
      'listen_type': 'single',
      'payload': [listen],
    });
  });

  test('maps rate limiting to a retry delay', () async {
    respond(
      429,
      {'code': 429, 'error': 'Too many requests'},
      headers: {
        'X-RateLimit-Reset-In': ['7'],
      },
    );

    await expectLater(
      client.submitListens(
        token: 't',
        listenType: ListenType.import,
        payload: const [],
      ),
      throwsA(
        isA<ScrobbleException>()
            .having((e) => e.isRateLimited, 'isRateLimited', isTrue)
            .having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(seconds: 7),
            )
            .having((e) => e.message, 'message', 'Too many requests'),
      ),
    );
  });

  test('maps HTTP statuses onto scrobble failures', () {
    expect(ScrobbleException.fromStatus(401, 'nope').isUnauthorized, isTrue);
    expect(ScrobbleException.fromStatus(400, 'bad').isRejected, isTrue);
    expect(ScrobbleException.fromStatus(429, 'slow').isRateLimited, isTrue);
    final server = ScrobbleException.fromStatus(503, 'down');
    expect(server.isRejected, isFalse);
    expect(server.failure, ScrobbleFailure.unavailable);
    expect(
      ScrobbleException.fromStatus(null, 'offline').failure,
      ScrobbleFailure.unavailable,
    );
  });
}
