import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../provider_container.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClientAdapter mockAdapter;
  late MockSecureStorage mockStorage;

  const credentials = UserCredentials(
    username: 'alex',
    pw: 'hunter2',
    serverUrl: 'http://jelly.local',
  );

  Future<String?> loginResult() async {
    final container = createProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(mockStorage)],
    );
    container.read(dioProvider).httpClientAdapter = mockAdapter;
    await container.read(authProvider.future);
    return container.read(authProvider.notifier).login(credentials);
  }

  void respondWithStatus(int statusCode) {
    when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => ResponseBody.fromString(
        jsonEncode({'error': 'nope'}),
        statusCode,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  setUpAll(() {
    deviceId = 'test-device';
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(const Stream<Uint8List>.empty());
  });

  setUp(() {
    mockAdapter = MockHttpClientAdapter();
    mockStorage = MockSecureStorage();
    when(
      () => mockStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(mockStorage.deleteAll).thenAnswer((_) async {});
  });

  group('AuthNotifier.login', () {
    test('- reports bad credentials when the server answers 401', () async {
      respondWithStatus(401);

      expect(await loginResult(), AuthNotifier.invalidCredentialsError);
    });

    test('- reports bad credentials when the server answers 403', () async {
      respondWithStatus(403);

      expect(await loginResult(), AuthNotifier.invalidCredentialsError);
    });

    test('- reports an unreachable server on a connection timeout', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(
        DioException.connectionTimeout(
          timeout: const Duration(seconds: 15),
          requestOptions: RequestOptions(path: '/Users/AuthenticateByName'),
        ),
      );

      expect(await loginResult(), AuthNotifier.serverUnreachableError);
    });

    test('- reports an unreachable server on a connection error', () async {
      when(() => mockAdapter.fetch(any(), any(), any())).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/Users/AuthenticateByName'),
          reason: 'no route to host',
        ),
      );

      expect(await loginResult(), AuthNotifier.serverUnreachableError);
    });

    test('- reports an unreachable server when the server errors', () async {
      respondWithStatus(500);

      expect(await loginResult(), AuthNotifier.serverUnreachableError);
    });
  });
}
