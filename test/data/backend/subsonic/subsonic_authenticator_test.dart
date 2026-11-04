import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_authenticator.dart';
import 'package:jplayer/src/data/params/params.dart';

import 'subsonic_test_support.dart';

void main() {
  const serverUrl = 'http://music.local';
  const credentials = UserCredentials(
    username: 'joe',
    pw: 'sesame',
    serverUrl: serverUrl,
  );

  late SubsonicFakeServer server;
  late SubsonicAuthenticator authenticator;

  setUpAll(registerSubsonicFallbacks);

  setUp(() {
    server = SubsonicFakeServer();
    authenticator = SubsonicAuthenticator(server.dio);
  });

  group('SubsonicAuthenticator', () {
    test(
      '- signs in with a salted token and never sends the password',
      () async {
        server.ok('ping', const {});

        final session = await authenticator.signIn(
          credentials,
          serverUrl: serverUrl,
        );

        final pings = server.calls('ping');
        expect(pings, hasLength(1));
        expect(pings.single.queryParameters.containsKey('p'), isFalse);
        expect(pings.single.queryParameters['t'], isNotEmpty);
        expect(pings.single.queryParameters['s'], isNotEmpty);
        expect(session.userId, 'joe');
        expect(session.token, isNot(contains('sesame')));
        expect(
          session.token,
          startsWith('${pings.single.queryParameters['t']}:'),
        );
      },
    );

    test(
      '- falls back to the plain password when tokens are unsupported',
      () async {
        server.on(
          'ping',
          (uri) => uri.queryParameters.containsKey('t')
              ? subsonicFailed(41, 'Token-based authentication not supported')
              : subsonicOk(),
        );

        final session = await authenticator.signIn(
          credentials,
          serverUrl: serverUrl,
        );

        final pings = server.calls('ping');
        expect(pings, hasLength(2));
        expect(pings.first.queryParameters.containsKey('p'), isFalse);
        expect(pings.last.queryParameters['p'], 'sesame');
        expect(pings.last.queryParameters.containsKey('t'), isFalse);
        expect(session.token, 'plain:sesame');
      },
    );

    test('- does not retry a wrong password in plain text', () async {
      server.on(
        'ping',
        (_) => subsonicFailed(40, 'Wrong username or password'),
      );

      await expectLater(
        authenticator.signIn(credentials, serverUrl: serverUrl),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      expect(server.calls('ping'), hasLength(1));
    });
  });
}
