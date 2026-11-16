import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/fanart/fanart_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optional_features/catalog.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class _MemoryStore implements CatalogCacheStore {
  final Map<String, CatalogCacheEntry> entries = {};

  @override
  Future<CatalogCacheEntry?> read(String source, String key) async =>
      entries['$source:$key'];

  @override
  Future<void> write(
    String source,
    String key,
    String json, {
    required DateTime expires,
  }) async {
    entries['$source:$key'] = CatalogCacheEntry(
      json: json,
      fetchedAt: DateTime(2026),
      expires: expires,
    );
  }
}

void main() {
  const mbid = 'a74b1b7f-71a5-4011-9441-d0b5e4122711';
  const ownKeys = FanartCredentials(apiKey: 'project', clientKey: 'me');
  const assets = 'https://assets.fanart.tv/fanart/music/$mbid';
  const artist = {
    'name': 'Radiohead',
    'mbid_id': mbid,
    'artistbackground': [
      {'id': '1', 'url': '$assets/artistbackground/a.jpg', 'likes': '2'},
      {'id': '2', 'url': '$assets/artistbackground/b.jpg', 'likes': '7'},
      {'id': '3', 'url': '', 'likes': '9'},
    ],
    'albums': <String, dynamic>{},
  };

  late MockHttpClientAdapter adapter;
  late _MemoryStore store;
  var now = DateTime(2026, 11, 15);

  setUpAll(() => registerFallbackValue(RequestOptions()));

  setUp(() {
    adapter = MockHttpClientAdapter();
    store = _MemoryStore();
    now = DateTime(2026, 11, 15);
  });

  FanartClient build({CatalogCacheStore? cache}) => FanartClient(
    userAgent: 'JellyBox/test (https://example.com)',
    linkUrl: 'https://link.test',
    cache: cache,
    now: () => now,
  )..dio.httpClientAdapter = adapter;

  ResponseBody response(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  void respond(int status, Object body) => when(
    () => adapter.fetch(any(), any(), any()),
  ).thenAnswer((_) async => response(status, body));

  RequestOptions sentRequest() =>
      verify(() => adapter.fetch(captureAny(), any(), any())).captured.single
          as RequestOptions;

  test('goes through Jellybox Link when the user has no keys', () async {
    respond(200, artist);

    final images = await build().artist(mbid, FanartCredentials.none);

    final request = sentRequest();
    expect(
      request.uri.toString(),
      'https://link.test/integrations/fanart/music/$mbid',
    );
    expect(
      request.headers['User-Agent'],
      'JellyBox/test (https://example.com)',
    );
    expect([for (final image in images.backgrounds) image.id], ['2', '1']);
  });

  test('passes only a personal key on to Jellybox Link', () async {
    respond(200, artist);

    await build().artist(mbid, const FanartCredentials(clientKey: 'me'));

    final request = sentRequest();
    expect(request.uri.path, '/integrations/fanart/music/$mbid');
    expect(request.uri.queryParameters, {'client_key': 'me'});
  });

  test('an own project key goes straight to fanart.tv', () async {
    respond(200, artist);

    await build().artist(mbid, ownKeys);

    final request = sentRequest();
    expect(request.uri.host, 'webservice.fanart.tv');
    expect(request.uri.path, '/v3.2/music/$mbid');
    expect(request.uri.queryParameters, {
      'api_key': 'project',
      'client_key': 'me',
    });
  });

  test('an unknown artist yields no images and is cached for a day', () async {
    respond(404, {'status': 'error', 'error message': 'not found'});

    final images = await build(
      cache: store,
    ).artist(mbid, FanartCredentials.none);

    expect(images.isEmpty, isTrue);
    expect(
      store.entries['fanart:music/$mbid']?.expires,
      now.add(FanartClient.noImagesLifetime),
    );
  });

  test('a rejected key throws badKey', () async {
    respond(401, {'status': 'error', 'error message': 'invalid api key'});

    await expectLater(
      build().artist(mbid, ownKeys),
      throwsA(
        isA<FanartException>().having(
          (error) => error.failure,
          'failure',
          FanartFailure.badKey,
        ),
      ),
    );
  });

  test('validate uses the same route as lookups', () async {
    respond(200, artist);
    await build().validate(ownKeys);
    expect(
      sentRequest().uri.toString(),
      startsWith(
        'https://webservice.fanart.tv/v3.2/music/'
        '${FanartClient.validationArtistId}?',
      ),
    );

    respond(200, artist);
    await build().validate(const FanartCredentials(clientKey: 'me'));
    expect(
      sentRequest().uri.path,
      '/integrations/fanart/music/${FanartClient.validationArtistId}',
    );

    respond(403, {'status': 'error', 'error message': 'nope'});
    await expectLater(
      build().validate(ownKeys),
      throwsA(isA<FanartException>()),
    );
  });

  test(
    'a cached answer is served without a request until it expires',
    () async {
      respond(200, artist);
      final client = build(cache: store);
      await client.artist(mbid, FanartCredentials.none);

      final cached = await client.artist(mbid, FanartCredentials.none);

      verify(() => adapter.fetch(any(), any(), any())).called(1);
      expect(cached.backgrounds.first.id, '2');

      now = now.add(FanartClient.imagesLifetime + const Duration(minutes: 1));
      await client.artist(mbid, FanartCredentials.none);
      verify(() => adapter.fetch(any(), any(), any())).called(1);
    },
  );

  test('a stale cache entry is reused when the lookup fails', () async {
    respond(200, artist);
    final client = build(cache: store);
    await client.artist(mbid, FanartCredentials.none);
    now = now.add(FanartClient.imagesLifetime + const Duration(days: 1));
    respond(503, {
      'status': 'error',
      'error message': 'fanart.tv is not configured on this server',
    });

    final images = await client.artist(mbid, FanartCredentials.none);

    expect(images.backgrounds.first.id, '2');
  });
}
