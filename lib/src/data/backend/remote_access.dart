import 'package:flutter/foundation.dart';

@immutable
class RemoteAccess {
  const RemoteAccess({required this.url, required this.fingerprint});

  final String url;
  final String fingerprint;

  @override
  bool operator ==(Object other) =>
      other is RemoteAccess &&
      other.url == url &&
      other.fingerprint == fingerprint;

  @override
  int get hashCode => Object.hash(url, fingerprint);
}

@immutable
class RemoteAccessResult {
  const RemoteAccessResult({this.access, this.denied});

  final RemoteAccess? access;
  final String? denied;

  @override
  bool operator ==(Object other) =>
      other is RemoteAccessResult &&
      other.access == access &&
      other.denied == denied;

  @override
  int get hashCode => Object.hash(access, denied);
}
