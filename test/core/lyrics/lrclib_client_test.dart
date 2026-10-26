import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/lyrics/lrclib_client.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  late MockHttpClientAdapter adapter;
  late LrclibClient client;

  const track = {
    'id': 3396226,
    'trackName': 'I Want to Live',
    'artistName': 'Borislav Slavov',
    'albumName': "Baldur's Gate 3",
    'duration': 233,
    'instrumental': false,
    'plainLyrics': 'I want to live',
    'syncedLyrics': '[00:17.12] I want to live',
  };

  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    client = LrclibClient(userAgent: 'JellyBox vTest (https://example.com)')
      ..dio.httpClientAdapter = adapter;
  });

  void respond(int status, Object body) {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  RequestOptions sentRequest() =>
      verify(() => adapter.fetch(captureAny(), any(), any())).captured.single
          as RequestOptions;

  test('find queries /api/get with the track signature', () async {
    respond(200, track);

    final result = await client.find(
      trackName: 'I Want to Live',
      artistName: 'Borislav Slavov',
      albumName: "Baldur's Gate 3",
      duration: const Duration(minutes: 3, seconds: 53),
    );

    expect(result!.id, 3396226);
    expect(result.hasSynced, isTrue);
    expect(result.duration, const Duration(seconds: 233));
    final request = sentRequest();
    expect(request.method, 'GET');
    expect(request.uri.host, 'lrclib.net');
    expect(request.uri.path, '/api/get');
    expect(request.uri.queryParameters, {
      'track_name': 'I Want to Live',
      'artist_name': 'Borislav Slavov',
      'album_name': "Baldur's Gate 3",
      'duration': '233',
    });
    expect(
      request.headers['User-Agent'],
      'JellyBox vTest (https://example.com)',
    );
  });

  test('find returns null on 404', () async {
    respond(404, {'statusCode': 404, 'name': 'TrackNotFound'});

    final result = await client.find(
      trackName: 'Unknown',
      artistName: 'Nobody',
      albumName: 'Nothing',
      duration: const Duration(seconds: 100),
    );

    expect(result, isNull);
  });

  test('find surfaces server errors', () async {
    respond(500, {'message': 'boom'});

    expect(
      () => client.find(
        trackName: 'Song',
        artistName: 'Artist',
        albumName: 'Album',
        duration: const Duration(seconds: 100),
      ),
      throwsA(isA<DioException>()),
    );
  });

  test('search queries /api/search and parses the list', () async {
    respond(200, [track, track]);

    final results = await client.search(
      trackName: 'I Want to Live',
      artistName: 'Borislav Slavov',
    );

    expect(results, hasLength(2));
    expect(results.first.trackName, 'I Want to Live');
    final request = sentRequest();
    expect(request.uri.path, '/api/search');
    expect(request.uri.queryParameters, {
      'track_name': 'I Want to Live',
      'artist_name': 'Borislav Slavov',
    });
  });

  test('search returns an empty list for an empty response', () async {
    respond(200, <Object>[]);

    expect(await client.search(trackName: 'Nothing'), isEmpty);
  });
}
