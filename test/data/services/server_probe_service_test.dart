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

  group('serverUrlCandidates', () {
    test('- tries http then https when no scheme is given', () {
      expect(serverUrlCandidates('jelly.local:8096'), [
        'http://jelly.local:8096',
        'https://jelly.local:8096',
      ]);
    });

    test('- only tries what the user typed when a scheme is given', () {
      expect(serverUrlCandidates('https://jelly.local'), [
        'https://jelly.local',
      ]);
    });

    test('- has no candidates for empty input', () {
      expect(serverUrlCandidates('   '), isEmpty);
    });
  });

  group('ServerProbeService.discover', () {
    test('- resolves a scheme-less url over http when http answers', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        respondWith(jsonBody({'Id': 'a', 'Version': '10.9.11'}, 200)),
      );

      final result = await service.discover('jelly.local:8096');

      expect(result, isNotNull);
      expect(result!.serverUrl, 'http://jelly.local:8096');
      expect(result.serverType, ServerType.jellyfin);
    });

    test('- falls back to https when http does not answer', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        if (options.uri.scheme == 'http') {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'refused',
          );
        }
        return jsonBody({'Id': 'a', 'Version': '10.9.11'}, 200);
      });

      final result = await service.discover('jelly.example.com');

      expect(result, isNotNull);
      expect(result!.serverUrl, 'https://jelly.example.com');
    });

    test('- returns null when neither scheme answers', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/System/Info/Public'),
          reason: 'refused',
        ),
      );

      expect(await service.discover('jelly.local'), isNull);
    });

    test('- does not guess a scheme the user already gave', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/System/Info/Public'),
          reason: 'refused',
        ),
      );

      expect(await service.discover('https://jelly.local'), isNull);

      final requested =
          verify(
            () => mockAdapter.fetch(captureAny(), any(), any()),
          ).captured.cast<RequestOptions>().map(
            (options) => options.uri.toString(),
          );
      expect(requested, [
        'https://jelly.local/System/Info/Public',
        'https://jelly.local/emby/System/Info/Public',
        'https://jelly.local/rest/ping.view?v=1.16.1&c=JellyBox&f=json',
      ]);
    });

    test('- identifies Emby from the /System/Ping product name', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        if (options.uri.path.endsWith('/System/Ping')) {
          return ResponseBody.fromString(
            'Emby Server',
            200,
            headers: {
              Headers.contentTypeHeader: ['text/plain'],
            },
          );
        }
        return jsonBody({'Id': 'a', 'Version': '4.9.5.0'}, 200);
      });

      final result = await service.discover('localhost:8096');

      expect(result!.serverType, ServerType.emby);
    });

    test('- identifies Jellyfin from the /System/Ping product name '
        'when the public info omits one', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        if (options.uri.path.endsWith('/System/Ping')) {
          return ResponseBody.fromString(
            'Jellyfin Server',
            200,
            headers: {
              Headers.contentTypeHeader: ['text/plain'],
            },
          );
        }
        return jsonBody({'Id': 'a', 'Version': '10.9.11'}, 200);
      });

      final result = await service.discover('localhost:8096');

      expect(result!.serverType, ServerType.jellyfin);
    });

    test(
      '- does not ping when the public info already names the product',
      () async {
        when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
          respondWith(
            jsonBody({
              'Id': 'a',
              'Version': '10.9.11',
              'ProductName': 'Jellyfin Server',
            }, 200),
          ),
        );

        await service.discover('localhost:8096');

        final requested = verify(
          () => mockAdapter.fetch(captureAny(), any(), any()),
        ).captured.cast<RequestOptions>();
        expect(
          requested.where((o) => o.uri.path.endsWith('/System/Ping')),
          isEmpty,
        );
      },
    );

    test(
      '- falls back to the address lists when nothing names the product',
      () async {
        when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
          respondWith(
            jsonBody({
              'LocalAddresses': <String>[],
              'RemoteAddresses': <String>[],
              'ServerName': '7dc78385bff0',
              'Version': '4.9.5.0',
              'Id': '25f50aa1ce3145439e758a520898bb26',
            }, 200),
          ),
        );

        final result = await service.discover('localhost:8096');

        expect(result!.serverUrl, 'http://localhost:8096');
        expect(result.serverType, ServerType.emby);
      },
    );

    test('- detects Emby from the public info product name', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        respondWith(
          jsonBody({
            'Id': 'a',
            'Version': '4.8.10.0',
            'ProductName': 'Emby Server',
          }, 200),
        ),
      );

      final result = await service.discover('http://emby.local:8096');

      expect(result!.serverUrl, 'http://emby.local:8096');
      expect(result.serverType, ServerType.emby);
    });

    test('- falls back to the /emby path prefix when the root '
        'does not answer', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        if (!options.uri.path.startsWith('/emby')) {
          return jsonBody({'error': 'nope'}, 404);
        }
        return jsonBody({'Id': 'a', 'Version': '4.8.10.0'}, 200);
      });

      final result = await service.discover('http://emby.local:8096');

      expect(result!.serverUrl, 'http://emby.local:8096/emby');
      expect(result.serverType, ServerType.emby);
    });

    test('- offers the jellyfin api of a subsonic server as an '
        'alternate', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        final path = options.uri.path;
        if (path.startsWith('/rest/')) {
          return jsonBody({
            'subsonic-response': {
              'status': 'ok',
              'version': '1.16.1',
              'type': 'navidrome',
              'serverVersion': '0.64.1',
            },
          }, 200);
        }
        if (path == '/jellyfin/System/Info/Public') {
          return jsonBody({
            'Id': 'be7d6efe',
            'Version': '12.1.0',
            'ProductName': 'Jellyfin Server',
            'ServerName': 'Navidrome 0.64.1',
          }, 200);
        }
        if (path == '/jellyfin/QuickConnect/Enabled') {
          return jsonBody(true, 200);
        }
        return jsonBody({'error': 'nope'}, 404);
      });

      final result = await service.discover('http://navi.local:4533');

      expect(result!.serverType, ServerType.subsonic);
      expect(result.serverUrl, 'http://navi.local:4533');
      expect(result.alternateApis, hasLength(1));

      final alternate = result.alternateApis.single;
      expect(alternate.serverType, ServerType.jellyfin);
      expect(alternate.serverUrl, 'http://navi.local:4533/jellyfin');
      expect(alternate.serverId, 'be7d6efe');
      expect(alternate.quickConnect, isTrue);
    });

    test('- leaves a subsonic server alone when it has no jellyfin '
        'api', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        if (options.uri.path.startsWith('/rest/')) {
          return jsonBody({
            'subsonic-response': {
              'status': 'ok',
              'version': '1.16.1',
              'type': 'navidrome',
            },
          }, 200);
        }
        return jsonBody({'error': 'nope'}, 404);
      });

      final result = await service.discover('http://navi.local:4533');

      expect(result!.serverType, ServerType.subsonic);
      expect(result.alternateApis, isEmpty);
    });

    test('- never looks for an alternate api on a jellyfin server', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        respondWith(
          jsonBody({
            'Id': 'a',
            'Version': '10.9.11',
            'ProductName': 'Jellyfin Server',
          }, 200),
        ),
      );

      final result = await service.discover('http://jelly.local:8096');

      expect(result!.alternateApis, isEmpty);
      final requested =
          verify(
            () => mockAdapter.fetch(captureAny(), any(), any()),
          ).captured.cast<RequestOptions>().map(
            (options) => options.uri.path,
          );
      expect(requested, isNot(contains(startsWith('/jellyfin'))));
    });

    test('- keeps a jellyfin server found at the root', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        respondWith(
          jsonBody({
            'Id': 'a',
            'Version': '10.9.11',
            'ProductName': 'Jellyfin Server',
          }, 200),
        ),
      );

      final result = await service.discover('http://jelly.local:8096');

      expect(result!.serverUrl, 'http://jelly.local:8096');
      expect(result.serverType, ServerType.jellyfin);
    });
  });

  group('ServerProbeService.detectType', () {
    test('- falls back to the ping product name when the public info '
        'is unavailable', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        if (options.uri.path.endsWith('/System/Ping')) {
          return ResponseBody.fromString(
            'Emby Server',
            200,
            headers: {
              Headers.contentTypeHeader: ['text/plain'],
            },
          );
        }
        return jsonBody({'error': 'nope'}, 404);
      });

      expect(await service.detectType('http://media.local'), ServerType.emby);
    });

    test('- has no answer when neither the info nor the ping does', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/System/Ping'),
          reason: 'refused',
        ),
      );

      expect(await service.detectType('http://media.local'), isNull);
    });
  });

  group('serverPathCandidates', () {
    test('- tries the root then the /emby prefix', () {
      expect(serverPathCandidates('http://media.local:8096'), [
        'http://media.local:8096',
        'http://media.local:8096/emby',
      ]);
    });

    test('- does not append /emby twice', () {
      expect(serverPathCandidates('http://media.local:8096/emby'), [
        'http://media.local:8096/emby',
      ]);
    });

    test('- drops a trailing slash', () {
      expect(serverPathCandidates('http://media.local:8096/'), [
        'http://media.local:8096',
        'http://media.local:8096/emby',
      ]);
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
        expect(info!.name, 'Living Room');
        expect(info.version, '10.9.11');
      },
    );

    test('- asks a Jellyfin server whether Quick Connect is on', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        if (options.uri.path.endsWith('/QuickConnect/Enabled')) {
          return jsonBody(true, 200);
        }
        return jsonBody({
          'Id': 'a',
          'Version': '10.9.11',
          'ProductName': 'Jellyfin Server',
        }, 200);
      });

      final info = await service.probe('http://jelly.local');

      expect(info?.quickConnect, isTrue);
    });

    test('- treats a failed Quick Connect check as off', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        if (options.uri.path.endsWith('/QuickConnect/Enabled')) {
          return jsonBody({'error': 'nope'}, 404);
        }
        return jsonBody({
          'Id': 'a',
          'Version': '10.9.11',
          'ProductName': 'Jellyfin Server',
        }, 200);
      });

      final info = await service.probe('http://jelly.local');

      expect(info?.quickConnect, isFalse);
    });

    test('- never asks an Emby server about Quick Connect', () async {
      final requested = <RequestOptions>[];
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        requested.add(options);
        return jsonBody({
          'Id': 'a',
          'Version': '4.8.0',
          'ProductName': 'Emby Server',
        }, 200);
      });

      final info = await service.probe('http://emby.local');

      expect(info?.quickConnect, isFalse);
      expect(
        requested.where((o) => o.uri.path.endsWith('/QuickConnect/Enabled')),
        isEmpty,
      );
    });

    test('- requests the public system info endpoint', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        respondWith(jsonBody({'Id': 'a', 'Version': '10.9.11'}, 200)),
      );

      await service.probe('http://jelly.local');

      final captured =
          verify(
                () => mockAdapter.fetch(captureAny(), any(), any()),
              ).captured.first
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
