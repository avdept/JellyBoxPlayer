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
class PluginNotice {
  const PluginNotice({required this.code, this.message});

  static const outdated = PluginNotice(code: 'plugin_outdated');

  final String code;
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is PluginNotice && other.code == code && other.message == message;

  @override
  int get hashCode => Object.hash(code, message);
}

@immutable
class RemoteAccessResult {
  const RemoteAccessResult({this.access, this.denied, this.notice});

  final RemoteAccess? access;
  final String? denied;
  final PluginNotice? notice;

  @override
  bool operator ==(Object other) =>
      other is RemoteAccessResult &&
      other.access == access &&
      other.denied == denied &&
      other.notice == notice;

  @override
  int get hashCode => Object.hash(access, denied, notice);
}
