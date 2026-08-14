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

  group('AuthNotifier.build', () {
    test(
      '- migrates a token stored under the pre-refactor key name so '
      'upgrading does not force a re-login',
      () async {
        when(
          () => mockStorage.read(key: 'serverUrl'),
        ).thenAnswer((_) async => 'http://jelly.local');
        when(
          () => mockStorage.read(key: 'userId'),
        ).thenAnswer((_) async => 'user-1');
        when(
          () => mockStorage.read(key: 'authToken'),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorage.read(key: 'x-mediabrowser-token'),
        ).thenAnswer((_) async => 'legacy-token');
        when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
          (_) async => ResponseBody.fromString(
            jsonEncode({'Items': <dynamic>[], 'TotalRecordCount': 0}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        final container = createProviderContainer(
          overrides: [secureStorageProvider.overrideWithValue(mockStorage)],
        );
        container.read(dioProvider).httpClientAdapter = mockAdapter;

        final restored = await container.read(authProvider.future);

        expect(restored, isTrue);
        verify(
          () => mockStorage.write(key: 'authToken', value: 'legacy-token'),
        ).called(1);
      },
    );

    test(
      '- does not re-read the legacy key once a token exists under the '
      'current one',
      () async {
        when(
          () => mockStorage.read(key: 'serverUrl'),
        ).thenAnswer((_) async => 'http://jelly.local');
        when(
          () => mockStorage.read(key: 'userId'),
        ).thenAnswer((_) async => 'user-1');
        when(
          () => mockStorage.read(key: 'authToken'),
        ).thenAnswer((_) async => 'current-token');
        when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
          (_) async => ResponseBody.fromString(
            jsonEncode({'Items': <dynamic>[], 'TotalRecordCount': 0}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

        final container = createProviderContainer(
          overrides: [secureStorageProvider.overrideWithValue(mockStorage)],
        );
        container.read(dioProvider).httpClientAdapter = mockAdapter;

        final restored = await container.read(authProvider.future);

        expect(restored, isTrue);
        verifyNever(() => mockStorage.read(key: 'x-mediabrowser-token'));
      },
    );
  });
}
