import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/network/certificate_trust.dart';
import 'package:jplayer/src/core/network/server_location.dart';
import 'package:jplayer/src/core/network/stream_proxy_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late HttpServer origin;
  late StreamProxyServer proxy;
  late List<HttpHeaders> received;
  late List<Uri> requested;
  late Uri originBase;

  String? playlistBody;

  setUp(() async {
    received = [];
    requested = [];
    playlistBody = null;
    origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    originBase = Uri.parse('http://127.0.0.1:${origin.port}');
    origin.listen((request) async {
      received.add(request.headers);
      requested.add(request.uri);
      final response = request.response;
      if (request.uri.path.endsWith('.m3u8')) {
        response.headers.contentType = ContentType(
          'application',
          'vnd.apple.mpegurl',
        );
        response.write(playlistBody);
        await response.close();
        return;
      }
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null) {
        response
          ..statusCode = HttpStatus.partialContent
          ..headers.set(HttpHeaders.contentRangeHeader, 'bytes 2-4/9')
          ..headers.contentType = ContentType('audio', 'flac')
          ..write('cde');
      } else {
        response
          ..headers.contentType = ContentType('audio', 'flac')
          ..headers.set(HttpHeaders.acceptRangesHeader, 'bytes')
          ..write('abcdefghi');
      }
      await response.close();
    });

    proxy = StreamProxyServer(
      shouldProxy: (uri) => uri.host == '127.0.0.1' && uri.port == origin.port,
    );
  });

  tearDown(() async {
    await proxy.close();
    await origin.close(force: true);
  });

  Future<HttpClientResponse> get(Uri uri, {String? range}) async {
    final client = HttpClient();
    final request = await client.getUrl(uri);
    if (range != null) request.headers.set(HttpHeaders.rangeHeader, range);
    request.headers.set('x-emby-token', 'token-1');
    final response = await request.close();
    return response;
  }

  test('leaves a uri it should not proxy untouched', () async {
    final untouched = Uri.parse('https://elsewhere.example/Audio/1/universal');

    expect(await proxy.resolve(untouched), untouched);
    expect(proxy.port, isNull);
  });

  test('streams the origin body through loopback', () async {
    final proxied = await proxy.resolve(originBase.resolve('/Audio/1/x.flac'));

    expect(proxied.host, '127.0.0.1');
    expect(proxied.port, isNot(origin.port));

    final response = await get(proxied);

    expect(response.statusCode, 200);
    expect(response.headers.contentType?.mimeType, 'audio/flac');
    expect(response.headers.value(HttpHeaders.acceptRangesHeader), 'bytes');
    expect(await response.transform(utf8.decoder).join(), 'abcdefghi');
  });

  test('forwards range requests and partial responses', () async {
    final proxied = await proxy.resolve(originBase.resolve('/Audio/1/x.flac'));

    final response = await get(proxied, range: 'bytes=2-4');

    expect(response.statusCode, 206);
    expect(
      response.headers.value(HttpHeaders.contentRangeHeader),
      'bytes 2-4/9',
    );
    expect(await response.transform(utf8.decoder).join(), 'cde');
    expect(received.single.value(HttpHeaders.rangeHeader), 'bytes=2-4');
  });

  test('forwards authorization headers to the origin', () async {
    final proxied = await proxy.resolve(originBase.resolve('/Audio/1/x.flac'));

    await (await get(proxied)).drain<void>();

    expect(received.single.value('x-emby-token'), 'token-1');
  });

  test('rewrites hls playlists so segments stay on the proxy', () async {
    playlistBody =
        '#EXTM3U\n'
        '#EXT-X-KEY:METHOD=AES-128,URI="$originBase/key?k=1"\n'
        '#EXTINF:6.0,\n'
        'hls1/main/0.mp4\n'
        '#EXTINF:6.0,\n'
        '$originBase/hls1/main/1.mp4\n'
        '#EXT-X-ENDLIST\n';

    final proxied = await proxy.resolve(
      originBase.resolve('/Audio/1/main.m3u8'),
    );
    final body = await (await get(proxied)).transform(utf8.decoder).join();
    final lines = const LineSplitter().convert(body);

    final segments = lines.where((line) => !line.startsWith('#')).toList();
    expect(segments, hasLength(2));
    for (final segment in segments) {
      expect(segment, startsWith('http://127.0.0.1:${proxy.port}/'));
    }
    expect(
      Uri.parse(segments.first).queryParameters['u'],
      base64Url.encode(utf8.encode('$originBase/Audio/1/hls1/main/0.mp4')),
    );
    expect(
      lines[1],
      startsWith('#EXT-X-KEY:METHOD=AES-128,URI="http://127.0.0.1:'),
    );
    expect(lines.last, '#EXT-X-ENDLIST');
  });

  test('refuses a request that does not carry the session secret', () async {
    await proxy.resolve(originBase.resolve('/Audio/1/x.flac'));
    final forged = Uri.parse(
      'http://127.0.0.1:${proxy.port}/guessed/x.flac'
      '?u=${base64Url.encode(utf8.encode('$originBase/Audio/1/x.flac'))}',
    );

    expect((await get(forged)).statusCode, HttpStatus.forbidden);
    expect(received, isEmpty);
  });

  test('refuses to proxy a target outside the trusted server', () async {
    final proxied = await proxy.resolve(originBase.resolve('/Audio/1/x.flac'));
    final elsewhere = proxied.replace(
      queryParameters: {
        'u': base64Url.encode(utf8.encode('http://example.com/secret')),
      },
    );

    expect((await get(elsewhere)).statusCode, HttpStatus.forbidden);
  });

  group('the predicate the app ships with', () {
    late CertificateTrust trust;
    late StreamProxyServer server;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      trust = CertificateTrust();
      await trust.load(await SharedPreferences.getInstance());
      await trust.trust(
        ServerCertificate(
          host: 'jelly.local',
          port: 8920,
          fingerprint: 'aa11',
          subject: '/CN=jelly.local',
          issuer: '/CN=jelly.local',
          validFrom: DateTime.utc(DateTime.now().year),
          validTo: DateTime.utc(DateTime.now().year + 1),
        ),
      );
      server = StreamProxyServer(
        shouldProxy: (uri) =>
            uri.isScheme('https') && trust.isTrusted(uri.host, uri.port),
      );
    });

    tearDown(() => server.close());

    Future<void> expectUntouched(String url) async {
      final uri = Uri.parse(url);

      expect(await server.resolve(uri), same(uri));
      expect(server.port, isNull);
    }

    test('leaves a plain http server alone', () async {
      await expectUntouched('http://jelly.local:8096/Audio/1/universal');
    });

    test('leaves a downloaded file alone', () async {
      await expectUntouched('file:///music/song.flac');
    });

    test('leaves an https server with a trusted ca alone', () async {
      await expectUntouched('https://jellyfin.example.com/Audio/1/universal');
    });

    test('leaves an unpinned port on a pinned host alone', () async {
      await expectUntouched('https://jelly.local:9000/Audio/1/universal');
    });

    test('proxies the pinned server, implicit port included', () async {
      await trust.trust(
        ServerCertificate(
          host: 'jelly.local',
          port: 443,
          fingerprint: 'bb22',
          subject: '/CN=jelly.local',
          issuer: '/CN=jelly.local',
          validFrom: DateTime.utc(DateTime.now().year),
          validTo: DateTime.utc(DateTime.now().year + 1),
        ),
      );

      final resolved = await server.resolve(
        Uri.parse('https://jelly.local/Audio/1/universal'),
      );

      expect(resolved.host, '127.0.0.1');
      expect(resolved.port, server.port);
    });
  });

  group('server locations', () {
    late List<String> endpoints;
    late List<String> switched;

    setUp(() async {
      endpoints = ['$originBase/jellyfin'];
      switched = [];
      await proxy.close();
      proxy = StreamProxyServer(
        shouldProxy: (_) => false,
        endpoints: () => endpoints,
        onEndpointSwitched: switched.add,
        connectTimeout: const Duration(seconds: 2),
      );
    });

    Future<String> deadEndpoint() async {
      final closed = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = closed.port;
      await closed.close(force: true);
      return 'http://127.0.0.1:$port';
    }

    test('joins the location with the live endpoint per request', () async {
      final uri = await proxy.forLocation(
        Uri.parse('Audio/1/x.flac?ApiKey=k'),
      );

      expect(uri.host, '127.0.0.1');
      expect(uri.toString(), isNot(contains(':${origin.port}')));

      final response = await get(uri);

      expect(response.statusCode, 200);
      expect(await response.transform(utf8.decoder).join(), 'abcdefghi');
      expect(requested.single.path, '/jellyfin/Audio/1/x.flac');
      expect(requested.single.queryParameters['ApiKey'], 'k');
      expect(switched, isEmpty);
    });

    test('follows the endpoint list between requests', () async {
      final uri = await proxy.forLocation(Uri.parse('Audio/1/x.flac'));
      await (await get(uri)).drain<void>();
      endpoints = ['$originBase/elsewhere'];
      await (await get(uri)).drain<void>();

      expect(requested.map((request) => request.path), [
        '/jellyfin/Audio/1/x.flac',
        '/elsewhere/Audio/1/x.flac',
      ]);
    });

    test('fails over to the next endpoint and reports the switch', () async {
      endpoints = [await deadEndpoint(), '$originBase/jellyfin'];
      final uri = await proxy.forLocation(Uri.parse('Audio/1/x.flac'));

      final response = await get(uri);

      expect(response.statusCode, 200);
      expect(await response.transform(utf8.decoder).join(), 'abcdefghi');
      expect(requested.single.path, '/jellyfin/Audio/1/x.flac');
      expect(switched, ['$originBase/jellyfin']);
    });

    test('skips an endpoint a block page answers for', () async {
      final blocker = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => blocker.close(force: true));
      blocker.listen((request) async {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
      });
      endpoints = ['http://127.0.0.1:${blocker.port}', '$originBase/jellyfin'];
      final uri = await proxy.forLocation(Uri.parse('Audio/1/x.flac'));

      final response = await get(uri);

      expect(response.statusCode, 200);
      expect(await response.transform(utf8.decoder).join(), 'abcdefghi');
      expect(switched, ['$originBase/jellyfin']);
    });

    test('answers 502 when no endpoint reaches the server', () async {
      endpoints = [await deadEndpoint()];
      final uri = await proxy.forLocation(Uri.parse('Audio/1/x.flac'));

      expect((await get(uri)).statusCode, HttpStatus.badGateway);
      expect(switched, isEmpty);
    });

    test('refuses a location while no endpoint is known', () async {
      endpoints = [];
      final uri = await proxy.forLocation(Uri.parse('Audio/1/x.flac'));

      expect((await get(uri)).statusCode, HttpStatus.forbidden);
      expect(requested, isEmpty);
    });

    test('refuses an absolute url smuggled as a location', () async {
      final uri = await proxy.forLocation(Uri.parse('Audio/1/x.flac'));
      final smuggled = uri.replace(
        queryParameters: {
          'l': base64Url.encode(utf8.encode('http://example.com/secret')),
        },
      );

      expect((await get(smuggled)).statusCode, HttpStatus.forbidden);
      expect(requested, isEmpty);
    });

    test('keeps hls segments on the proxy as locations', () async {
      playlistBody =
          '#EXTM3U\n'
          '#EXT-X-KEY:METHOD=AES-128,URI="$originBase/jellyfin/key?k=1"\n'
          '#EXTINF:6.0,\n'
          'hls1/main/0.mp4\n'
          '#EXTINF:6.0,\n'
          '$originBase/jellyfin/hls1/main/1.mp4\n'
          '#EXT-X-ENDLIST\n';
      final uri = await proxy.forLocation(Uri.parse('Audio/1/main.m3u8'));

      final body = await (await get(uri)).transform(utf8.decoder).join();
      final lines = const LineSplitter().convert(body);
      final segments = lines.where((line) => !line.startsWith('#')).toList();

      String locationOf(String line) => utf8.decode(
        base64Url.decode(Uri.parse(line).queryParameters['l']!),
      );
      expect(segments, hasLength(2));
      expect(locationOf(segments[0]), 'Audio/1/hls1/main/0.mp4');
      expect(locationOf(segments[1]), 'hls1/main/1.mp4');
      expect(lines[1], contains('URI="http://127.0.0.1:${proxy.port}/'));

      endpoints = ['$originBase/moved'];
      await (await get(Uri.parse(segments[0]))).drain<void>();
      expect(requested.last.path, '/moved/Audio/1/hls1/main/0.mp4');
    });
  });

  group('server location helpers', () {
    test('join honours a path prefix and keeps the query', () {
      final joined = joinServerLocation(
        'https://host:8920/jellyfin/',
        Uri.parse('Audio/1/universal?ApiKey=k&Container=flac,mp3'),
      );

      expect(
        joined.toString(),
        'https://host:8920/jellyfin/Audio/1/universal?ApiKey=k&Container=flac,mp3',
      );
    });

    test('strips the base back off a url under it', () {
      final location = serverLocationOf(
        Uri.parse('https://host:8920/jellyfin/Audio/1/universal?ApiKey=k'),
        'https://host:8920/jellyfin',
      );

      expect(location.toString(), 'Audio/1/universal?ApiKey=k');
      expect(
        serverLocationOf(
          Uri.parse('https://other/jellyfin/x'),
          'https://host:8920/jellyfin',
        ),
        isNull,
      );
      expect(
        serverLocationOf(
          Uri.parse('https://host:8920/other/x'),
          'https://host:8920/jellyfin',
        ),
        isNull,
      );
    });
  });
}
