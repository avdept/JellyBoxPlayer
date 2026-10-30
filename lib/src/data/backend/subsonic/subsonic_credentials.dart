import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';

const _saltLength = 16;
const _hexDigits = '0123456789abcdef';

String subsonicSalt({Random? random}) {
  final rng = random ?? Random.secure();
  return String.fromCharCodes(
    Iterable.generate(
      _saltLength,
      (_) => _hexDigits.codeUnitAt(rng.nextInt(_hexDigits.length)),
    ),
  );
}

String subsonicTokenFor({required String password, required String salt}) =>
    md5.convert(utf8.encode('$password$salt')).toString();

String subsonicServerId(String serverUrl) =>
    serverUrl.trim().replaceAll(RegExp(r'/+$'), '');

enum SubSonicCredentialsKind {
  legacy,
  token,
}

class SubsonicCredentials {
  const SubsonicCredentials({
    required this.kind,
    required this.username,
    required this.token,
    required this.salt,
  }) : assert(
         salt != null || kind == SubSonicCredentialsKind.legacy,
         'salt is required for token based auth',
       );

  factory SubsonicCredentials.fromPassword({
    required String username,
    required String password,
    required SubSonicCredentialsKind kind,
    String? salt,
  }) {
    final resolvedSalt = salt ?? subsonicSalt();
    return SubsonicCredentials(
      kind: kind,
      username: username,
      token: kind == SubSonicCredentialsKind.legacy
          ? password
          : subsonicTokenFor(password: password, salt: resolvedSalt),
      salt: resolvedSalt,
    );
  }

  static SubsonicCredentials? decode({
    required String username,
    required String encodedToken,
  }) {
    final parts = encodedToken.split(':');

    final kind = switch (parts.length) {
      2 => SubSonicCredentialsKind.token,
      3 => SubSonicCredentialsKind.values.firstWhereOrNull(
        (kind) => kind.name == parts.first,
      ),
      _ => null,
    };
    if (kind == null) {
      return null;
    }

    final (token, salt) = (parts[parts.length - 2], parts[parts.length - 1]);

    if (token.isEmpty || (kind == SubSonicCredentialsKind.token && salt.isEmpty)) {
      return null;
    }

    return SubsonicCredentials(
      kind: kind,
      username: username,
      token: token,
      salt: salt,
    );
  }

  final String username;
  final SubSonicCredentialsKind kind;
  final String token;
  final String? salt;

  String get encodedToken => '${kind.name}:$token:$salt';

  Map<String, String> get queryParameters => {
    'u': username,
    if (kind == SubSonicCredentialsKind.legacy)
      'p': token
    else ...{
      't': token,
      's': ?salt,
    },
  };
}
