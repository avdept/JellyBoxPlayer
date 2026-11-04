import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/musicbrainz/barcode_match.dart';
import 'package:jplayer/src/core/musicbrainz/musicbrainz_client.dart';
import 'package:jplayer/src/core/musicbrainz/musicbrainz_models.dart';
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
  const kidA = 'e75c0549-ad55-39e3-8025-c72c5d4a3c5d';
  const radiohead = 'a74b1b7f-71a5-4011-9441-d0b5e4122711';

  late Map<String, dynamic> fixture;
  late MockHttpClientAdapter adapter;
  late List<Duration> waits;
  late DateTime now;

  setUpAll(() async {
    registerFallbackValue(RequestOptions());
    fixture =
        jsonDecode(
              await File(
                'test/fixtures/musicbrainz/release_barcode_724352775323.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    waits = [];
    now = DateTime(2026, 10, 28);
  });

  MusicBrainzClient build({CatalogCacheStore? cache}) => MusicBrainzClient(
    userAgent: 'JellyBox/test (https://example.com)',
    cache: cache,
    now: () => now,
    wait: (duration) async {
      waits.add(duration);
      now = now.add(duration);
    },
  )..dio.httpClientAdapter = adapter;

  ResponseBody response(
    int status,
    Object body, {
    Map<String, List<String>> headers = const {},
  }) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );

  void respond(int status, Object body) {
    when(
      () => adapter.fetch(any(), any(), any()),
    ).thenAnswer((_) async => response(status, body));
  }

  List<RequestOptions> sentRequests() => verify(
    () => adapter.fetch(captureAny(), any(), any()),
  ).captured.cast<RequestOptions>();

  group('releasesByBarcode', () {
    test('searches with a quoted barcode and identifies itself', () async {
      respond(200, fixture);

      final releases = await build().releasesByBarcode('0724352775323');

      final request = sentRequests().single;
      expect(request.uri.path, '/ws/2/release');
      expect(request.uri.queryParameters['query'], 'barcode:"724352775323"');
      expect(request.uri.queryParameters['fmt'], 'json');
      expect(
        request.headers['User-Agent'],
        'JellyBox/test (https://example.com)',
      );
      expect(releases, hasLength(7));
    });

    test('parses the release, its group, artist, media and label', () async {
      respond(200, fixture);

      final releases = await build().releasesByBarcode('724352775323');
      final release = releases.firstWhere(
        (r) => r.country == 'US' && r.isOfficial,
      );

      expect(release.title, 'Kid A');
      expect(release.releaseGroup.id, kidA);
      expect(release.releaseGroup.primaryType, 'Album');
      expect(release.primaryArtist?.id, radiohead);
      expect(release.artistName, 'Radiohead');
      expect(release.date, '2000-10-03');
      expect(release.year, 2000);
      expect(release.trackCount, 10);
      expect(release.media.single.format, 'CD');
      expect(release.labels.single.labelName, 'Capitol Records');
      expect(release.labels.single.catalogNumber, 'CDP 7243 5 27753 2 3');
    });

    test('does not ask for something that is not a barcode', () async {
      expect(await build().releasesByBarcode('n/a'), isEmpty);
      expect(await build().releasesByBarcode('1234'), isEmpty);
      verifyNever(() => adapter.fetch(any(), any(), any()));
    });

    test(
      'retries when MusicBrainz sheds load, honouring Retry-After',
      () async {
        var calls = 0;
        when(() => adapter.fetch(any(), any(), any())).thenAnswer((_) async {
          calls++;
          if (calls == 1) {
            return response(
              503,
              {'error': 'The MusicBrainz web server is currently busy.'},
              headers: {
                'retry-after': ['2'],
              },
            );
          }
          if (calls == 2) return response(503, {'error': 'busy'});
          return response(200, fixture);
        });

        final releases = await build().releasesByBarcode('724352775323');

        expect(releases, hasLength(7));
        expect(calls, 3);
        expect(waits, contains(const Duration(seconds: 2)));
      },
    );

    test('an unidentified client error is not retried', () async {
      respond(403, {'error': 'Your requests are being throttled'});

      await expectLater(
        build().releasesByBarcode('724352775323'),
        throwsA(
          isA<MusicBrainzException>().having(
            (e) => e.statusCode,
            'status',
            403,
          ),
        ),
      );
      expect(sentRequests(), hasLength(1));
    });

    test('spaces requests at least a second apart', () async {
      respond(200, fixture);
      final client = build();

      await client.releasesByBarcode('724352775323');
      await client.releasesByBarcode('5099969710629');

      expect(waits.single, MusicBrainzClient.minInterval);
    });
  });

  group('cache', () {
    test('a later client answers from the store, misses included', () async {
      final store = _MemoryStore();
      respond(200, fixture);
      await build(cache: store).releasesByBarcode('724352775323');
      respond(200, {'count': 0, 'offset': 0, 'releases': <Object>[]});
      await build(cache: store).releasesByBarcode('111111111111');

      final hit = await build(cache: store).releasesByBarcode('0724352775323');
      final miss = await build(cache: store).releasesByBarcode('111111111111');

      expect(hit, hasLength(7));
      expect(miss, isEmpty);
      expect(sentRequests(), hasLength(2));
    });

    test('an expired entry still answers when the request fails', () async {
      final store = _MemoryStore();
      respond(200, fixture);
      await build(cache: store).releasesByBarcode('724352775323');
      now = now.add(
        MusicBrainzClient.barcodeLifetime + const Duration(days: 1),
      );
      respond(503, {'error': 'busy'});

      final releases = await build(
        cache: store,
      ).releasesByBarcode('724352775323');

      expect(releases, hasLength(7));
    });
  });

  group('pickReleaseMatch', () {
    late List<MusicBrainzRelease> releases;

    setUp(() {
      releases = MusicBrainzReleaseSearch.fromJson(fixture).releases;
    });

    test(
      'chooses the release group most releases share, ignoring bootlegs',
      () {
        final match = pickReleaseMatch(releases, barcode: '0724352775323');

        expect(match?.releaseGroupId, kidA);
        expect(match?.artistId, radiohead);
        expect(match?.releases, hasLength(6));
        expect(match?.releases.every((r) => !r.isBootleg), isTrue);
      },
    );

    test('insists on the artist when one is given', () {
      expect(
        pickReleaseMatch(
          releases,
          barcode: '724352775323',
          artistName: 'radiohead',
        )?.releaseGroupId,
        kidA,
      );
      expect(
        pickReleaseMatch(
          releases,
          barcode: '724352775323',
          artistName: 'David Byrne',
        ),
        isNull,
      );
    });

    test('ignores hits whose barcode differs', () {
      expect(pickReleaseMatch(releases, barcode: '724352775316'), isNull);
    });
  });

  test('normalizeBarcode treats UPC-A and EAN-13 forms as one', () {
    expect(normalizeBarcode('0724352775323'), '724352775323');
    expect(normalizeBarcode('724352775323'), '724352775323');
    expect(normalizeBarcode('5099969710629'), '5099969710629');
    expect(normalizeBarcode('7 24352 77532 3'), '724352775323');
    expect(normalizeBarcode(''), isNull);
    expect(normalizeBarcode('0000000000000'), isNull);
  });
}
