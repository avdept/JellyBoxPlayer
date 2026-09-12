import 'package:dio/dio.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/backend/server_identity.dart';
import 'package:jplayer/src/data/backend/server_probe.dart';
import 'package:jplayer/src/data/backend/server_type.dart';
import 'package:jplayer/src/data/dto/dto.dart';

const embyPathPrefix = '/emby';

String _withoutTrailingSlash(String url) => url.replaceAll(RegExp(r'/+$'), '');

List<String> serverPathCandidates(String serverUrl) {
  final trimmed = _withoutTrailingSlash(serverUrl);
  if (trimmed.toLowerCase().endsWith(embyPathPrefix)) return [trimmed];
  return [trimmed, '$trimmed$embyPathPrefix'];
}

ServerType? serverTypeFromProductName(String? productName) {
  final product = productName?.toLowerCase() ?? '';
  if (product.contains('jellyfin')) return ServerType.jellyfin;
  if (product.contains('emby')) return ServerType.emby;
  return null;
}

ServerType serverTypeOf(
  PublicSystemInfoDTO info, {
  required String serverUrl,
}) {
  final named = serverTypeFromProductName(info.productName);
  if (named != null) return named;
  if (serverUrl.toLowerCase().endsWith(embyPathPrefix)) return ServerType.emby;
  final reportsAddressLists =
      info.localAddresses != null || info.remoteAddresses != null;
  return reportsAddressLists ? ServerType.emby : ServerType.jellyfin;
}

class MediaBrowserProbe extends ServerProbe {
  const MediaBrowserProbe(this._client);

  final Dio _client;

  @override
  ServerType get serverType => ServerType.jellyfin;

  @override
  List<String> pathCandidates(String serverUrl) =>
      serverPathCandidates(serverUrl);

  @override
  Future<ServerIdentity?> identify(String serverUrl) async {
    final info = await publicInfo(serverUrl);
    if (info == null) return null;
    final serverType = await resolveServerType(info, serverUrl: serverUrl);
    return ServerIdentity(
      serverUrl: serverUrl,
      serverType: serverType,
      serverId: info.id,
      name: info.serverName,
      version: info.version,
      productName: info.productName,
      quickConnect: switch (serverType) {
        ServerType.jellyfin => await quickConnectEnabled(serverUrl),
        ServerType.emby => false,
      },
    );
  }

  Future<bool> quickConnectEnabled(String serverUrl) async {
    try {
      final response = await JellyfinApi(
        _client,
        baseUrl: serverUrl,
      ).quickConnectEnabled();
      return response.data;
    } on Object {
      return false;
    }
  }

  @override
  Future<ServerType?> identifyType(String serverUrl) async {
    final info = await publicInfo(serverUrl);
    if (info != null) return resolveServerType(info, serverUrl: serverUrl);
    return serverTypeFromProductName(await ping(serverUrl));
  }

  Future<ServerType> resolveServerType(
    PublicSystemInfoDTO info, {
    required String serverUrl,
  }) async {
    final fromInfo = serverTypeFromProductName(info.productName);
    if (fromInfo != null) return fromInfo;

    final fromPing = serverTypeFromProductName(await ping(serverUrl));
    if (fromPing != null) return fromPing;

    return serverTypeOf(info, serverUrl: serverUrl);
  }

  Future<String?> ping(String serverUrl) async {
    try {
      final response = await _client.get<String>(
        '$serverUrl/System/Ping',
        options: Options(responseType: ResponseType.plain),
      );
      return response.data;
    } on Object {
      return null;
    }
  }

  Future<PublicSystemInfoDTO?> publicInfo(String serverUrl) async {
    try {
      final response = await JellyfinApi(
        _client,
        baseUrl: serverUrl,
      ).getPublicSystemInfo();
      final info = response.data;
      return (info.id != null && info.version != null) ? info : null;
    } on Object {
      return null;
    }
  }
}
