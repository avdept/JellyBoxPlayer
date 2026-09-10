import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/network/stream_proxy_server.dart';

void main() {
  late HttpServer origin;
  late StreamProxyServer proxy;
  late List<HttpHeaders> received;
  late Uri originBase;

  String? playlistBody;

  setUp(() async {
    received = [];
    playlistBody = null;
    origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    originBase = Uri.parse('http://127.0.0.1:${origin.port}');
    origin.listen((request) async {
      received.add(request.headers);
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
}
