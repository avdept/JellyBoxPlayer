import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    client = LrclibClient(
      userAgent: 'JellyBox vTest (https://example.com)',
      retryDelay: Duration.zero,
    )..dio.httpClientAdapter = adapter;
  });

  ResponseBody response(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  void respond(int status, Object body) {
    when(
      () => adapter.fetch(any(), any(), any()),
    ).thenAnswer((_) async => response(status, body));
  }

  void respondInTurn(List<Object Function()> answers) {
    var call = 0;
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((_) async {
      final answer = answers[call < answers.length ? call : answers.length - 1];
      call++;
      return answer() as ResponseBody;
    });
  }

  Future<LrclibTrack?> find() => client.find(
    trackName: 'Song',
    artistName: 'Artist',
    albumName: 'Album',
    duration: const Duration(seconds: 100),
  );

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

  test('find surfaces server errors after the last retry', () async {
    respond(500, {'message': 'boom'});

    await expectLater(find, throwsA(isA<DioException>()));
    verify(
      () => adapter.fetch(any(), any(), any()),
    ).called(LrclibClient.maxRetries + 1);
    expect(client.retrying.value, isFalse);
  });

  test('find retries a server error and returns the later answer', () async {
    respondInTurn([
      () => response(503, {'message': 'busy'}),
      () => response(200, track),
    ]);

    final result = await find();

    expect(result!.id, 3396226);
    verify(() => adapter.fetch(any(), any(), any())).called(2);
  });

  test('search retries a dropped connection', () async {
    respondInTurn([
      () => throw const SocketException('reset'),
      () => response(200, [track]),
    ]);

    expect(await client.search(trackName: 'Song'), hasLength(1));
    verify(() => adapter.fetch(any(), any(), any())).called(2);
  });

  test('a 404 or a client error is not retried', () async {
    respond(404, {'statusCode': 404, 'name': 'TrackNotFound'});
    expect(await find(), isNull);
    verify(() => adapter.fetch(any(), any(), any())).called(1);

    respond(400, {'message': 'bad request'});
    await expectLater(find, throwsA(isA<DioException>()));
    verify(() => adapter.fetch(any(), any(), any())).called(1);
  });

  test('retrying stays on from the first failure to the last answer', () async {
    final seen = <bool>[];
    client.retrying.addListener(() => seen.add(client.retrying.value));
    final gate = Completer<void>();
    var calls = 0;
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((_) async {
      calls++;
      if (calls == 1) return response(500, {'message': 'boom'});
      await gate.future;
      return response(200, track);
    });

    final pending = find();
    while (calls < 2) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(client.retrying.value, isTrue);
    gate.complete();
    await pending;

    expect(client.retrying.value, isFalse);
    expect(seen, [true, false]);
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
