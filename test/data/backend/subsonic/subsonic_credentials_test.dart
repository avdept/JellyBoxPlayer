import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_credentials.dart';

void main() {
  group('SubsonicCredentials', () {
    test('- hashes the password with the salt as md5 hex', () {
      final credentials = SubsonicCredentials.fromPassword(
        kind: SubSonicCredentialsKind.token,
        username: 'joe',
        password: 'sesame',
        salt: 'c19b2d',
      );

      expect(credentials.token, '26719a1196d2a940705a59634eb18eab');
      expect(credentials.queryParameters, {
        'u': 'joe',
        't': '26719a1196d2a940705a59634eb18eab',
        's': 'c19b2d',
      });
    });

    test('- passes the plain text password in legacy mode', () {
      final credentials = SubsonicCredentials.fromPassword(
        kind: SubSonicCredentialsKind.legacy,
        username: 'joe',
        password: 'sesame',
      );

      expect(credentials.token, 'sesame');
      expect(credentials.queryParameters, {
        'u': 'joe',
        'p': 'sesame',
      });
    });

    test('- round-trips through the stored token form', () {
      final original = SubsonicCredentials.fromPassword(
        kind: SubSonicCredentialsKind.token,
        username: 'joe',
        password: 'sesame',
      );

      final decoded = SubsonicCredentials.decode(
        username: 'joe',
        encodedToken: original.encodedToken,
      );

      expect(decoded?.token, original.token);
      expect(decoded?.salt, original.salt);
      expect(decoded?.queryParameters, original.queryParameters);
    });

    test('- decodes old non-kind stored token form', () {
      final decoded = SubsonicCredentials.decode(
        username: 'joe',
        encodedToken: 'token:salt',
      );

      expect(decoded?.token, 'token');
      expect(decoded?.salt, 'salt');
    });

    test('- rejects malformed stored tokens', () {
      expect(
        SubsonicCredentials.decode(username: 'joe', encodedToken: ''),
        isNull,
      );
      expect(
        SubsonicCredentials.decode(username: 'joe', encodedToken: 'abc'),
        isNull,
      );
      expect(
        SubsonicCredentials.decode(username: 'joe', encodedToken: 'abc:'),
        isNull,
      );
      expect(
        SubsonicCredentials.decode(username: 'joe', encodedToken: ':salt'),
        isNull,
      );
      expect(
        SubsonicCredentials.decode(
          username: 'joe',
          encodedToken: 'invalid:token:salt',
        ),
        isNull,
      );
    });

    test('- generates a fresh 16 character hex salt per login', () {
      final first = subsonicSalt(random: Random(1));
      final second = subsonicSalt(random: Random(2));

      expect(first, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(second, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(first, isNot(second));
    });
  });

  test('subsonicServerId strips whitespace and trailing slashes', () {
    expect(
      subsonicServerId(' http://music.local:4533/// '),
      'http://music.local:4533',
    );
    expect(
      subsonicServerId('https://music.local/nav/'),
      'https://music.local/nav',
    );
  });
}
