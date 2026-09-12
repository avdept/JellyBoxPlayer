import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_quick_connect.dart';
import 'package:jplayer/src/data/backend/quick_connect.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  late MockHttpClientAdapter adapter;
  late JellyfinQuickConnect quickConnect;
  late List<RequestOptions> requests;

  const serverUrl = 'http://jelly.local:8096';

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(const Stream<Uint8List>.empty());
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    requests = [];
    final dio = Dio()..httpClientAdapter = adapter;
    quickConnect = JellyfinQuickConnect(dio);
  });

  ResponseBody json(Object? body, [int statusCode = 200]) =>
      ResponseBody.fromString(
        jsonEncode(body),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  void routeWith(ResponseBody Function(RequestOptions options) handler) {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((
      invocation,
    ) async {
      final options = invocation.positionalArguments.first as RequestOptions;
      requests.add(options);
      return handler(options);
    });
  }

  group('initiate', () {
    test('- posts to /QuickConnect/Initiate and returns the code', () async {
      routeWith((_) => json({'Secret': 'secret-1', 'Code': '123456'}));

      final request = await quickConnect.initiate(serverUrl: serverUrl);

      expect(request.code, '123456');
      expect(request.secret, 'secret-1');
      expect(requests.single.method, 'POST');
      expect(requests.single.path, contains('/QuickConnect/Initiate'));
    });

    test('- surfaces server errors', () async {
      routeWith((_) => json({'error': 'nope'}, 500));

      await expectLater(
        quickConnect.initiate(serverUrl: serverUrl),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('poll', () {
    const request = QuickConnectRequest(code: '123456', secret: 'secret-1');

    test('- returns null while the request is not approved', () async {
      routeWith(
        (_) => json({
          'Secret': 'secret-1',
          'Code': '123456',
          'Authenticated': false,
        }),
      );

      expect(
        await quickConnect.poll(request, serverUrl: serverUrl),
        isNull,
      );
      expect(requests.single.path, contains('/QuickConnect/Connect'));
      expect(requests.single.queryParameters['secret'], 'secret-1');
    });

    test('- exchanges the secret for a session once approved', () async {
      routeWith(
        (options) => options.path.contains('/QuickConnect/Connect')
            ? json({
                'Secret': 'secret-1',
                'Code': '123456',
                'Authenticated': true,
              })
            : json({
                'User': {'Id': 'user-1', 'Name': 'alex'},
                'SessionInfo': {
                  'Id': 'session-1',
                  'PlayState': <String, dynamic>{},
                },
                'AccessToken': 'token-1',
                'ServerId': 'server-1',
              }),
      );

      final session = await quickConnect.poll(request, serverUrl: serverUrl);

      expect(session?.userId, 'user-1');
      expect(session?.token, 'token-1');
      expect(session?.serverId, 'server-1');
      expect(
        requests.last.path,
        contains('/Users/AuthenticateWithQuickConnect'),
      );
      expect(requests.last.data, isA<Object>());
      expect(jsonEncode(requests.last.data), contains('secret-1'));
    });

    test('- surfaces an expired request as a 404', () async {
      routeWith((_) => json({'error': 'nope'}, 404));

      await expectLater(
        quickConnect.poll(request, serverUrl: serverUrl),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });
  });
}
