import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  late MockHttpClientAdapter mockAdapter;
  late ServerProbeService service;

  ResponseBody jsonBody(Object? body, int statusCode) =>
      ResponseBody.fromString(
        jsonEncode(body),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  Future<ResponseBody> Function(Invocation) respondWith(ResponseBody body) =>
      (_) async => body;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(const Stream<Uint8List>.empty());
  });

  setUp(() {
    mockAdapter = MockHttpClientAdapter();
    service = ServerProbeService(
      client: Dio()..httpClientAdapter = mockAdapter,
    );
  });

  group('normalizeServerUrl', () {
    test('- prefixes http when no scheme is given', () {
      expect(normalizeServerUrl('jelly.local:8096'), 'http://jelly.local:8096');
    });

    test('- keeps an existing http scheme', () {
      expect(normalizeServerUrl('http://jelly.local'), 'http://jelly.local');
    });

    test('- keeps an existing https scheme', () {
      expect(normalizeServerUrl('https://jelly.local'), 'https://jelly.local');
    });

    test('- is case insensitive about the scheme', () {
      expect(normalizeServerUrl('HTTPS://jelly.local'), 'HTTPS://jelly.local');
    });

    test('- trims surrounding whitespace', () {
      expect(
        normalizeServerUrl('  http://jelly.local  '),
        'http://jelly.local',
      );
    });

    test('- does not treat a host starting with http as a scheme', () {
      expect(normalizeServerUrl('httpserver.local'), 'http://httpserver.local');
    });
  });

  group('ServerProbeService', () {
    test(
      '- returns the server info when the server is a Jellyfin server',
      () async {
        when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
          respondWith(
            jsonBody({
              'Id': 'server-id',
              'ServerName': 'Living Room',
              'Version': '10.9.11',
              'ProductName': 'Jellyfin Server',
            }, 200),
          ),
        );

        final info = await service.probe('http://jelly.local');

        expect(info, isNotNull);
        expect(info!.serverName, 'Living Room');
        expect(info.version, '10.9.11');
      },
    );

    test('- requests the public system info endpoint', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        respondWith(jsonBody({'Id': 'a', 'Version': '10.9.11'}, 200)),
      );

      await service.probe('http://jelly.local');

      final captured =
          verify(
                () => mockAdapter.fetch(captureAny(), any(), any()),
              ).captured.single
              as RequestOptions;
      expect(captured.uri.toString(), 'http://jelly.local/System/Info/Public');
      expect(captured.method, 'GET');
    });

    test('- returns null when the payload is not a Jellyfin server', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        respondWith(jsonBody({'hello': 'world'}, 200)),
      );

      expect(await service.probe('http://jelly.local'), isNull);
    });

    test('- returns null when the response is not json', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          '<html><body>hello</body></html>',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/html'],
          },
        ),
      );

      expect(await service.probe('http://jelly.local'), isNull);
    });

    test('- returns null when the server responds with an error', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        respondWith(jsonBody({'error': 'nope'}, 500)),
      );

      expect(await service.probe('http://jelly.local'), isNull);
    });

    test('- returns null when the server cannot be reached', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/System/Info/Public'),
          reason: 'no route to host',
        ),
      );

      expect(await service.probe('http://unreachable.local'), isNull);
    });

    test('- returns null when the request times out', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(
        DioException.connectionTimeout(
          timeout: const Duration(seconds: 6),
          requestOptions: RequestOptions(path: '/System/Info/Public'),
        ),
      );

      expect(await service.probe('http://unreachable.local'), isNull);
    });
  });
}
