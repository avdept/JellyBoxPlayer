import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/animated_artwork/hls_variant.dart';
import 'package:jplayer/src/core/animated_artwork/hls_variant_resolver.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

const _master = '''
#EXTM3U
#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=179042,CODECS="avc1.64001f",RESOLUTION=486x486,URI="trick_486.m3u8"
#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=266759,BANDWIDTH=288918,CODECS="avc1.64001f,mp4a.40.2",RESOLUTION=360x360
video_360.m3u8
#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=1161449,BANDWIDTH=1206308,CODECS="avc1.64001f",RESOLUTION=486x486
video_486_high.m3u8
#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=574493,BANDWIDTH=590000,CODECS="hvc1.2.20000000.L123.B0",RESOLUTION=486x486
video_486_low.m3u8
#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=1504911,BANDWIDTH=1621246,CODECS="hvc1.2.20000000.L123.B0",RESOLUTION=768x768
video_768.m3u8
#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=2508113,BANDWIDTH=2600000,CODECS="hvc1.2.20000000.L123.B0",RESOLUTION=1080x1080
video_1080.m3u8
#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=21834845,BANDWIDTH=22000000,CODECS="hvc1.2.20000000.H150.B0",RESOLUTION=2160x2160
video_2160.m3u8
''';

final Uri _base = Uri.parse('https://cdn.example.com/art/P1_default.m3u8');

void main() {
  group('parseHlsVariants', () {
    test('- reads every stream and resolves relative urls', () {
      final variants = parseHlsVariants(_master, base: _base);

      expect(variants, hasLength(6));
      expect(
        variants.first.url,
        Uri.parse('https://cdn.example.com/art/video_360.m3u8'),
      );
      expect(variants.first.width, 360);
      expect(variants.first.height, 360);
      expect(variants.first.bandwidth, 266759);
    });

    test('- skips i-frame trick-play streams', () {
      final variants = parseHlsVariants(_master, base: _base);

      expect(
        variants.map((variant) => variant.url.pathSegments.last),
        isNot(contains('trick_486.m3u8')),
      );
    });

    test('- keeps commas inside quoted attributes out of the split', () {
      final variants = parseHlsVariants(_master, base: _base);

      expect(variants.first.width, 360);
    });

    test('- prefers AVERAGE-BANDWIDTH but falls back to BANDWIDTH', () {
      const playlist = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=4242,RESOLUTION=100x100
only_peak.m3u8
''';

      expect(parseHlsVariants(playlist, base: _base).single.bandwidth, 4242);
    });

    test('- returns nothing for a media playlist', () {
      const playlist = '''
#EXTM3U
#EXT-X-TARGETDURATION:5
#EXTINF:2.50250,
#EXT-X-BYTERANGE:80511@897
segment.mp4
''';

      expect(parseHlsVariants(playlist, base: _base), isEmpty);
    });

    test('- returns nothing for a body that is not a playlist', () {
      expect(parseHlsVariants('<html>nope</html>', base: _base), isEmpty);
    });
  });

  group('pickHlsVariant', () {
    List<HlsVariant> variants() => parseHlsVariants(_master, base: _base);

    test('- takes the narrowest rung that still covers the target', () {
      final picked = pickHlsVariant(variants(), targetWidth: 400);

      expect(picked!.width, 486);
    });

    test('- takes the cheapest rung at the chosen resolution', () {
      final picked = pickHlsVariant(variants(), targetWidth: 400);

      expect(picked!.bandwidth, 574493);
      expect(picked.url.pathSegments.last, 'video_486_low.m3u8');
    });

    test('- takes an exact match over a larger rung', () {
      expect(pickHlsVariant(variants(), targetWidth: 360)!.width, 360);
    });

    test('- falls back to the widest rung when all are too small', () {
      expect(pickHlsVariant(variants(), targetWidth: 4000)!.width, 2160);
    });

    test('- never reaches for 2160 at a sane target width', () {
      for (final target in [1, 100, 360, 480, 720, 1080]) {
        expect(
          pickHlsVariant(variants(), targetWidth: target)!.width,
          lessThan(2160),
          reason: 'target $target',
        );
      }
    });

    test('- prefers a rung with a known bitrate', () {
      const playlist = '''
#EXTM3U
#EXT-X-STREAM-INF:RESOLUTION=100x100
unknown.m3u8
#EXT-X-STREAM-INF:AVERAGE-BANDWIDTH=900000,RESOLUTION=100x100
known.m3u8
''';

      final picked = pickHlsVariant(
        parseHlsVariants(playlist, base: _base),
        targetWidth: 100,
      );

      expect(picked!.url.pathSegments.last, 'known.m3u8');
    });

    test('- returns null when there is nothing to pick', () {
      expect(pickHlsVariant([], targetWidth: 720), isNull);
    });
  });

  group('HlsVariantResolver', () {
    late MockHttpClientAdapter adapter;
    late HlsVariantResolver resolver;

    setUpAll(() => registerFallbackValue(RequestOptions()));

    setUp(() {
      adapter = MockHttpClientAdapter();
      resolver = HlsVariantResolver(dio: Dio()..httpClientAdapter = adapter);
    });

    void respond(int status, String body) {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(body, status),
      );
    }

    test('- rewrites a master playlist to the chosen variant', () async {
      respond(200, _master);

      expect(
        await resolver.resolve(_base, targetWidth: 400),
        Uri.parse('https://cdn.example.com/art/video_486_low.m3u8'),
      );
    });

    test('- leaves a url that is not a playlist alone', () async {
      final url = Uri.parse('https://cdn.example.com/art/cover.mp4');

      expect(await resolver.resolve(url, targetWidth: 400), url);
      verifyNever(() => adapter.fetch(any(), any(), any()));
    });

    test('- falls back to the master url when the fetch fails', () async {
      when(
        () => adapter.fetch(any(), any(), any()),
      ).thenThrow(Exception('offline'));

      expect(await resolver.resolve(_base, targetWidth: 400), _base);
    });

    test('- falls back to the master url when it has no variants', () async {
      respond(200, '#EXTM3U\n#EXT-X-TARGETDURATION:5\n');

      expect(await resolver.resolve(_base, targetWidth: 400), _base);
    });

    test('- fetches a given url and width only once', () async {
      respond(200, _master);

      await resolver.resolve(_base, targetWidth: 400);
      await resolver.resolve(_base, targetWidth: 400);

      verify(() => adapter.fetch(any(), any(), any())).called(1);
    });

    test('- treats a different target width as a different lookup', () async {
      respond(200, _master);

      final small = await resolver.resolve(_base, targetWidth: 100);
      final large = await resolver.resolve(_base, targetWidth: 1000);

      expect(small, isNot(large));
      verify(() => adapter.fetch(any(), any(), any())).called(2);
    });
  });
}
