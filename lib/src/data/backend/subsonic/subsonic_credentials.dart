import 'dart:convert';
import 'dart:math';

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

class SubsonicCredentials {
  const SubsonicCredentials({
    required this.username,
    required this.token,
    required this.salt,
  });

  factory SubsonicCredentials.fromPassword({
    required String username,
    required String password,
    String? salt,
  }) {
    final resolvedSalt = salt ?? subsonicSalt();
    return SubsonicCredentials(
      username: username,
      token: subsonicTokenFor(password: password, salt: resolvedSalt),
      salt: resolvedSalt,
    );
  }

  static SubsonicCredentials? decode({
    required String username,
    required String encodedToken,
  }) {
    final separator = encodedToken.indexOf(':');
    if (separator <= 0 || separator == encodedToken.length - 1) return null;
    return SubsonicCredentials(
      username: username,
      token: encodedToken.substring(0, separator),
      salt: encodedToken.substring(separator + 1),
    );
  }

  final String username;
  final String token;
  final String salt;

  String get encodedToken => '$token:$salt';

  Map<String, String> get queryParameters => {
    'u': username,
    't': token,
    's': salt,
  };
}
