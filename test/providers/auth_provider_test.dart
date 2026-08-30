import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../provider_container.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockServerProbeService extends Mock implements ServerProbeService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClientAdapter mockAdapter;
  late MockSecureStorage mockStorage;
  late MockServerProbeService mockProbe;

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
    mockProbe = MockServerProbeService();
    when(() => mockProbe.probe(any())).thenAnswer(
      (_) async => const PublicSystemInfoDTO(
        id: 'server-id-from-probe',
        version: '10.9.11',
      ),
    );
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

  group('AuthNotifier authorization headers', () {
    final requests = <RequestOptions>[];

    void respondToSignIn() {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        requests.add(options);
        final body = options.path.contains('AuthenticateByName')
            ? jsonEncode({
                'User': {'Id': 'user-1', 'Name': 'alex'},
                'SessionInfo': {
                  'Id': 'session-1',
                  'PlayState': <String, dynamic>{},
                },
                'AccessToken': 'token-1',
                'ServerId': 'server-1',
              })
            : jsonEncode({'Items': <dynamic>[], 'TotalRecordCount': 0});
        return ResponseBody.fromString(
          body,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    }

    Future<Dio> signIn(ServerType serverType) async {
      final container = createProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(mockStorage)],
      );
      final dio = container.read(dioProvider)..httpClientAdapter = mockAdapter;
      await container.read(authProvider.future);
      await container
          .read(authProvider.notifier)
          .login(credentials, serverType: serverType);
      return dio;
    }

    Map<String, dynamic> signInHeaders() => requests
        .firstWhere((request) => request.path.contains('AuthenticateByName'))
        .headers;

    setUp(() {
      requests.clear();
      respondToSignIn();
    });

    test(
      '- identifies the client to Jellyfin through the Authorization header, '
      'which is the only form Jellyfin 12 still parses',
      () async {
        final dio = await signIn(ServerType.jellyfin);

        final sent = signInHeaders()['authorization'] as String;
        expect(sent, startsWith('MediaBrowser '));
        expect(sent, contains('Client="JellyBox Player"'));
        expect(sent, contains('DeviceId="test-device"'));
        expect(sent, isNot(contains('Token=')));
        expect(signInHeaders().containsKey('x-emby-authorization'), isFalse);

        expect(
          dio.options.headers['authorization'],
          contains('Token="token-1"'),
        );
        expect(
          dio.options.headers.containsKey('x-mediabrowser-token'),
          isFalse,
        );
      },
    );

    test(
      '- keeps identifying the client to Emby through X-Emby-Authorization',
      () async {
        final dio = await signIn(ServerType.emby);

        final sent = signInHeaders()['x-emby-authorization'] as String;
        expect(sent, startsWith('MediaBrowser '));
        expect(sent, contains('Client="JellyBox Player"'));
        expect(sent, contains('DeviceId="test-device"'));
        expect(signInHeaders().containsKey('authorization'), isFalse);

        expect(dio.options.headers['x-emby-token'], 'token-1');
        expect(dio.options.headers.containsKey('authorization'), isFalse);
      },
    );
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

  group('AuthNotifier server id backfill', () {
    Future<ProviderContainer> restoreSession({String? storedServerId}) async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((invocation) async {
        return switch (invocation.namedArguments[const Symbol('key')]) {
          'serverUrl' => 'http://jelly.local',
          'userId' => 'user-1',
          'authToken' => 'token-1',
          'serverId' => storedServerId,
          _ => null,
        };
      });
      respondWithStatus(200);

      final container = createProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          serverProbeServiceProvider.overrideWithValue(mockProbe),
        ],
      );
      container.read(dioProvider).httpClientAdapter = mockAdapter;
      await container.read(authProvider.future);
      return container;
    }

    test('- fetches the server id when none was stored yet', () async {
      final container = await restoreSession();

      verify(() => mockProbe.probe('http://jelly.local')).called(1);
      verify(
        () => mockStorage.write(key: 'serverId', value: 'server-id-from-probe'),
      ).called(1);
      expect(container.read(currentServerIdProvider), 'server-id-from-probe');
    });

    test('- never fetches again once the id is stored', () async {
      final container = await restoreSession(storedServerId: 'stored-id');

      verifyNever(() => mockProbe.probe(any()));
      verifyNever(
        () => mockStorage.write(
          key: 'serverId',
          value: any(named: 'value'),
        ),
      );
      expect(container.read(currentServerIdProvider), 'stored-id');
    });

    test('- leaves the id unset when the server cannot be reached', () async {
      when(() => mockProbe.probe(any())).thenAnswer((_) async => null);

      final container = await restoreSession();

      verify(() => mockProbe.probe('http://jelly.local')).called(1);
      verifyNever(
        () => mockStorage.write(
          key: 'serverId',
          value: any(named: 'value'),
        ),
      );
      expect(container.read(currentServerIdProvider), isNull);
    });
  });
}
