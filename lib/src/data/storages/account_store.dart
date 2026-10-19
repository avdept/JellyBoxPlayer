import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/src/data/backend/server_type.dart';

@immutable
class ServerAccount {
  const ServerAccount({
    required this.serverId,
    required this.serverType,
    required this.url,
    required this.userId,
    required this.token,
    this.userName,
    this.serverName,
    this.productName,
    this.remoteUrl,
    this.relayUrl,
    this.libraryId,
    this.libraryPath,
    this.libraryName,
    this.needsReauth = false,
  });

  factory ServerAccount.fromJson(Map<String, dynamic> json) => ServerAccount(
    serverId: json['serverId'] as String,
    serverType:
        ServerType.values.asNameMap()[json['serverType']] ??
        ServerType.jellyfin,
    url: json['url'] as String,
    userId: json['userId'] as String,
    token: json['token'] as String,
    userName: json['userName'] as String?,
    serverName: json['serverName'] as String?,
    productName: json['productName'] as String?,
    remoteUrl: json['remoteUrl'] as String?,
    relayUrl: json['relayUrl'] as String?,
    libraryId: json['libraryId'] as String?,
    libraryPath: json['libraryPath'] as String?,
    libraryName: json['libraryName'] as String?,
    needsReauth: json['needsReauth'] as bool? ?? false,
  );

  final String serverId;
  final ServerType serverType;
  final String url;
  final String userId;
  final String token;
  final String? userName;
  final String? serverName;
  final String? productName;
  final String? remoteUrl;
  final String? relayUrl;
  final String? libraryId;
  final String? libraryPath;
  final String? libraryName;
  final bool needsReauth;

  String get displayName {
    final name = serverName;
    if (name != null && name.isNotEmpty) return name;
    final host = Uri.tryParse(url)?.host;
    return host == null || host.isEmpty ? url : host;
  }

  ServerAccount copyWith({
    String? url,
    String? userId,
    String? token,
    String? Function()? userName,
    String? Function()? serverName,
    String? Function()? productName,
    String? Function()? remoteUrl,
    String? Function()? relayUrl,
    String? Function()? libraryId,
    String? Function()? libraryPath,
    String? Function()? libraryName,
    bool? needsReauth,
  }) => ServerAccount(
    serverId: serverId,
    serverType: serverType,
    url: url ?? this.url,
    userId: userId ?? this.userId,
    token: token ?? this.token,
    userName: userName == null ? this.userName : userName(),
    serverName: serverName == null ? this.serverName : serverName(),
    productName: productName == null ? this.productName : productName(),
    remoteUrl: remoteUrl == null ? this.remoteUrl : remoteUrl(),
    relayUrl: relayUrl == null ? this.relayUrl : relayUrl(),
    libraryId: libraryId == null ? this.libraryId : libraryId(),
    libraryPath: libraryPath == null ? this.libraryPath : libraryPath(),
    libraryName: libraryName == null ? this.libraryName : libraryName(),
    needsReauth: needsReauth ?? this.needsReauth,
  );

  Map<String, dynamic> toJson() => {
    'serverId': serverId,
    'serverType': serverType.name,
    'url': url,
    'userId': userId,
    'token': token,
    'userName': ?userName,
    'serverName': ?serverName,
    'productName': ?productName,
    'remoteUrl': ?remoteUrl,
    'relayUrl': ?relayUrl,
    'libraryId': ?libraryId,
    'libraryPath': ?libraryPath,
    'libraryName': ?libraryName,
    if (needsReauth) 'needsReauth': true,
  };

  @override
  bool operator ==(Object other) =>
      other is ServerAccount && mapEquals(other.toJson(), toJson());

  @override
  int get hashCode => Object.hashAll(toJson().values);
}

class AccountStore {
  AccountStore(this._storage);

  static const storageKey = 'accounts';

  final FlutterSecureStorage _storage;

  Future<List<ServerAccount>?> load() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .map((e) => ServerAccount.fromJson((e as Map).cast()))
          .toList();
    } on Object {
      return null;
    }
  }

  Future<void> save(List<ServerAccount> accounts) => _storage.write(
    key: storageKey,
    value: jsonEncode([for (final account in accounts) account.toJson()]),
  );
}
