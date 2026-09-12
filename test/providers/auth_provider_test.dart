import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/network/certificate_trust.dart';
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

  Future<String?> loginResult({CertificateTrust? trust}) async {
    final container = createProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
        if (trust != null) certificateTrustProvider.overrideWithValue(trust),
      ],
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
    registerFallbackValue(const PublicSystemInfoDTO());
    registerFallbackValue(const Stream<Uint8List>.empty());
  });

  setUp(() {
    mockAdapter = MockHttpClientAdapter();
    mockStorage = MockSecureStorage();
    mockProbe = MockServerProbeService();
    when(() => mockProbe.probe(any())).thenAnswer(
      (_) async => const ServerIdentity(
        serverUrl: 'http://jelly.local',
        serverType: ServerType.jellyfin,
        serverId: 'server-id-from-probe',
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

    test(
      '- reports an untrusted certificate when the handshake fails',
      () async {
        final trust = CertificateTrust();
        when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
          _,
        ) async {
          trust.allowsCertificate(
            ServerCertificate(
              host: 'jelly.local',
              port: 443,
              fingerprint: 'aa11',
              subject: '/CN=jelly.local',
              issuer: '/CN=jelly.local',
              validFrom: DateTime.utc(DateTime.now().year),
              validTo: DateTime.utc(DateTime.now().year + 1),
            ),
          );
          throw DioException.connectionError(
            requestOptions: RequestOptions(path: '/Users/AuthenticateByName'),
            reason: 'handshake failed',
          );
        });

        expect(
          await loginResult(trust: trust),
          AuthNotifier.untrustedCertificateError,
        );
      },
    );
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

  group('AuthNotifier.login server type', () {
    void respondWithSuccessfulLogin() {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        final body = options.uri.path.endsWith('/Users/AuthenticateByName')
            ? {
                'User': {'Id': 'user-1', 'Name': 'alex'},
                'SessionInfo': {'Id': 'session-1', 'PlayState': {}},
                'AccessToken': 'token-1',
                'ServerId': 'server-1',
              }
            : {'Items': <Object>[], 'TotalRecordCount': 0};
        return ResponseBody.fromString(
          jsonEncode(body),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    }

    Future<void> loginWith({ServerType? serverType}) async {
      final container = createProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          serverProbeServiceProvider.overrideWithValue(mockProbe),
        ],
      );
      container.read(dioProvider).httpClientAdapter = mockAdapter;
      await container.read(authProvider.future);
      await container
          .read(authProvider.notifier)
          .login(credentials, serverType: serverType);
    }

    test(
      '- identifies the server itself when the caller has no hint',
      () async {
        when(
          () => mockProbe.detectType(any()),
        ).thenAnswer((_) async => ServerType.emby);
        respondWithSuccessfulLogin();

        await loginWith();

        verify(() => mockProbe.detectType('http://jelly.local')).called(1);
        verify(
          () => mockStorage.write(key: 'serverType', value: 'emby'),
        ).called(1);
      },
    );

    test('- trusts a caller hint without identifying at all', () async {
      respondWithSuccessfulLogin();

      await loginWith(serverType: ServerType.emby);

      verifyNever(() => mockProbe.detectType(any()));
      verify(
        () => mockStorage.write(key: 'serverType', value: 'emby'),
      ).called(1);
    });

    test(
      '- falls back to Jellyfin when the server cannot be identified',
      () async {
        when(() => mockProbe.detectType(any())).thenAnswer((_) async => null);
        respondWithSuccessfulLogin();

        await loginWith();

        verify(
          () => mockStorage.write(key: 'serverType', value: 'jellyfin'),
        ).called(1);
      },
    );
  });

  group('AuthNotifier quick connect', () {
    final requests = <RequestOptions>[];

    ResponseBody jsonBody(Object? body, [int statusCode = 200]) =>
        ResponseBody.fromString(
          jsonEncode(body),
          statusCode,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );

    void routeQuickConnect({
      bool enabled = true,
      bool authenticated = true,
      int connectStatus = 200,
    }) {
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        final options = invocation.positionalArguments.first as RequestOptions;
        requests.add(options);
        final path = options.path;
        if (path.contains('/QuickConnect/Enabled')) return jsonBody(enabled);
        if (path.contains('/QuickConnect/Initiate')) {
          return jsonBody({'Secret': 'secret-1', 'Code': '123456'});
        }
        if (path.contains('/QuickConnect/Connect')) {
          if (connectStatus != 200) {
            return jsonBody({'error': 'nope'}, connectStatus);
          }
          return jsonBody({
            'Secret': 'secret-1',
            'Code': '123456',
            'Authenticated': authenticated,
          });
        }
        if (path.contains('AuthenticateWithQuickConnect')) {
          return jsonBody({
            'User': {'Id': 'user-1', 'Name': 'alex'},
            'SessionInfo': {
              'Id': 'session-1',
              'PlayState': <String, dynamic>{},
            },
            'AccessToken': 'token-1',
            'ServerId': 'server-1',
          });
        }
        return jsonBody({'Items': <dynamic>[], 'TotalRecordCount': 0});
      });
    }

    ProviderContainer containerWithAdapter() {
      final container = createProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          serverProbeServiceProvider.overrideWithValue(mockProbe),
        ],
      );
      container.read(dioProvider).httpClientAdapter = mockAdapter;
      return container;
    }

    setUp(requests.clear);

    test('- refuses to start on Emby', () async {
      routeQuickConnect();
      final container = containerWithAdapter();
      await container.read(authProvider.future);

      final request = await container
          .read(authProvider.notifier)
          .beginQuickConnect(
            'http://emby.local',
            serverType: ServerType.emby,
          );

      expect(request, isNull);
      expect(requests, isEmpty);
    });

    test('- signs in once the code is approved', () async {
      routeQuickConnect();
      final container = containerWithAdapter();
      await container.read(authProvider.future);
      final notifier = container.read(authProvider.notifier);

      final request = await notifier.beginQuickConnect(
        'http://jelly.local',
        serverType: ServerType.jellyfin,
      );
      expect(request?.code, '123456');

      expect(await notifier.awaitQuickConnect(), isNull);
      expect(container.read(authProvider).value, isTrue);
      verify(
        () => mockStorage.write(key: 'authToken', value: 'token-1'),
      ).called(1);
      verify(() => mockStorage.write(key: 'userId', value: 'user-1')).called(1);
      verify(
        () => mockStorage.write(key: 'serverType', value: 'jellyfin'),
      ).called(1);
    });

    test('- reports an expired code', () async {
      routeQuickConnect(connectStatus: 404);
      final container = containerWithAdapter();
      await container.read(authProvider.future);
      final notifier = container.read(authProvider.notifier);

      await notifier.beginQuickConnect(
        'http://jelly.local',
        serverType: ServerType.jellyfin,
      );

      expect(
        await notifier.awaitQuickConnect(),
        AuthNotifier.quickConnectExpiredError,
      );
      expect(container.read(authProvider).value, isFalse);
    });

    test('- stops polling when cancelled', () async {
      routeQuickConnect(authenticated: false);
      final container = containerWithAdapter();
      await container.read(authProvider.future);
      final notifier = container.read(authProvider.notifier);

      await notifier.beginQuickConnect(
        'http://jelly.local',
        serverType: ServerType.jellyfin,
      );
      requests.clear();
      notifier.cancelQuickConnect();

      expect(
        await notifier.awaitQuickConnect(),
        AuthNotifier.quickConnectCancelled,
      );
      expect(requests, isEmpty);
    });
  });
}
