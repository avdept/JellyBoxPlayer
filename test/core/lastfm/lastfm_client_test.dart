import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/lastfm/lastfm_client.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  const credentials = LastFmCredentials(apiKey: 'key', apiSecret: 'secret');

  late MockHttpClientAdapter adapter;
  late LastFmClient client;

  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    client = LastFmClient()..dio.httpClientAdapter = adapter;
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

  test('signs requests with the sorted parameters and the secret', () {
    final signed = LastFmClient.sign(credentials, 'track.scrobble', {
      'track[0]': 'Sour Times',
      'artist[0]': 'Portishead',
      'sk': 'session',
    });

    final expected = md5
        .convert(
          utf8.encode(
            'api_keykeyartist[0]Portisheadmethodtrack.scrobblesksessiontrack[0]Sour Timessecret',
          ),
        )
        .toString();
    expect(signed['api_sig'], expected);
    expect(signed['format'], 'json');
    expect(signed['api_key'], 'key');
    expect(signed['method'], 'track.scrobble');
  });

  test('getToken fetches a request token over GET', () async {
    respond(200, {'token': 'tok'});

    expect(await client.getToken(credentials), 'tok');
    final request = sentRequest();
    expect(request.method, 'GET');
    expect(request.uri.host, 'ws.audioscrobbler.com');
    expect(request.uri.queryParameters['method'], 'auth.getToken');
    expect(request.uri.queryParameters['api_key'], 'key');
    expect(request.uri.queryParameters['format'], 'json');
    expect(request.uri.queryParameters['api_sig'], isNotEmpty);
  });

  test('authorizationUrl points the browser at last.fm with the token', () {
    expect(
      LastFmClient.authorizationUrl(credentials, 'tok').toString(),
      'https://www.last.fm/api/auth/?api_key=key&token=tok',
    );
  });

  test('getSession returns the user and session key', () async {
    respond(200, {
      'session': {'name': 'alex', 'key': 'sk', 'subscriber': 0},
    });

    final session = await client.getSession(credentials, 'tok');

    expect(session.userName, 'alex');
    expect(session.key, 'sk');
    expect(sentRequest().uri.queryParameters['token'], 'tok');
  });

  test('getSession reports a token the user has not authorized yet', () async {
    respond(403, {
      'error': 14,
      'message': 'This token has not been authorized',
    });

    await expectLater(
      client.getSession(credentials, 'tok'),
      throwsA(
        isA<LastFmException>()
            .having((e) => e.tokenNotAuthorized, 'tokenNotAuthorized', isTrue)
            .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue),
      ),
    );
  });

  test('getToken flags a rejected API key or secret', () async {
    respond(403, {'error': 10, 'message': 'Invalid API key'});
    await expectLater(
      client.getToken(credentials),
      throwsA(
        isA<LastFmException>()
            .having((e) => e.badCredentials, 'badCredentials', isTrue)
            .having((e) => e.failure, 'failure', ScrobbleFailure.unavailable),
      ),
    );

    respond(403, {'error': 13, 'message': 'Invalid method signature'});
    await expectLater(
      client.getToken(credentials),
      throwsA(
        isA<LastFmException>().having(
          (e) => e.badCredentials,
          'badCredentials',
          isTrue,
        ),
      ),
    );
  });

  test('scrobble posts a signed form and reports ignored tracks', () async {
    respond(200, {
      'scrobbles': {
        '@attr': {'accepted': 1, 'ignored': 1},
        'scrobble': <Object>[],
      },
    });

    final ignored = await client.scrobble(credentials, {
      'artist[0]': 'A',
      'track[0]': 'B',
    }, sessionKey: 'sk');

    expect(ignored, 1);
    final request = sentRequest();
    expect(request.method, 'POST');
    expect(request.uri.toString(), LastFmClient.apiUrl);
    expect(request.contentType, Headers.formUrlEncodedContentType);
    final data = request.data as Map<String, String>;
    expect(data['method'], 'track.scrobble');
    expect(data['sk'], 'sk');
    expect(data['artist[0]'], 'A');
    expect(data['api_sig'], hasLength(32));
  });

  test('updateNowPlaying posts the track with the session key', () async {
    respond(200, {'nowplaying': <String, Object>{}});

    await client.updateNowPlaying(credentials, {
      'artist': 'A',
      'track': 'B',
    }, sessionKey: 'sk');

    final data = sentRequest().data as Map<String, String>;
    expect(data['method'], 'track.updateNowPlaying');
    expect(data['sk'], 'sk');
    expect(data.containsKey('timestamp'), isFalse);
  });

  test('maps Last.fm error codes onto scrobble failures', () async {
    respond(403, {'error': 9, 'message': 'Invalid session key'});
    await expectLater(
      client.updateNowPlaying(credentials, const {}, sessionKey: 'sk'),
      throwsA(
        isA<LastFmException>().having(
          (e) => e.isUnauthorized,
          'isUnauthorized',
          isTrue,
        ),
      ),
    );

    respond(429, {'error': 29, 'message': 'Rate limit exceeded'});
    await expectLater(
      client.updateNowPlaying(credentials, const {}, sessionKey: 'sk'),
      throwsA(
        isA<LastFmException>().having(
          (e) => e.isRateLimited,
          'isRateLimited',
          isTrue,
        ),
      ),
    );

    respond(200, {'error': 6, 'message': 'Invalid parameters'});
    await expectLater(
      client.updateNowPlaying(credentials, const {}, sessionKey: 'sk'),
      throwsA(
        isA<LastFmException>().having(
          (e) => e.isRejected,
          'isRejected',
          isTrue,
        ),
      ),
    );

    respond(503, {'error': 16, 'message': 'Temporary error'});
    await expectLater(
      client.updateNowPlaying(credentials, const {}, sessionKey: 'sk'),
      throwsA(
        isA<LastFmException>().having(
          (e) => e.failure,
          'failure',
          ScrobbleFailure.unavailable,
        ),
      ),
    );
  });

  test('a non-JSON failure becomes an unavailable scrobble error', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => ResponseBody.fromString(
        '<html></html>',
        502,
        headers: {
          Headers.contentTypeHeader: ['text/html'],
        },
      ),
    );

    await expectLater(
      client.getToken(credentials),
      throwsA(
        isA<ScrobbleException>().having(
          (e) => e.failure,
          'failure',
          ScrobbleFailure.unavailable,
        ),
      ),
    );
  });
}
