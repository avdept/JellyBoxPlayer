import 'package:dio/dio.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';

final _schemeRegExp = RegExp('^https?://', caseSensitive: false);

String normalizeServerUrl(String url) {
  final trimmed = url.trim();
  if (_schemeRegExp.hasMatch(trimmed)) return trimmed;
  return 'http://$trimmed';
}

List<String> serverUrlCandidates(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return const [];
  if (_schemeRegExp.hasMatch(trimmed)) return [trimmed];
  return ['http://$trimmed', 'https://$trimmed'];
}

enum ServerType {
  jellyfin,
  emby;

  String get label => switch (this) {
    ServerType.jellyfin => 'Jellyfin',
    ServerType.emby => 'Emby',
  };
}

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

class ServerProbeResult {
  const ServerProbeResult({
    required this.serverUrl,
    required this.serverType,
    required this.info,
  });

  final String serverUrl;
  final ServerType serverType;
  final PublicSystemInfoDTO info;
}

class ServerProbeService {
  ServerProbeService({Dio? client})
    : _client =
          client ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
              contentType: 'application/json',
            ),
          );

  final Dio _client;

  Future<ServerProbeResult?> discover(String url) async {
    for (final candidate in serverUrlCandidates(url)) {
      for (final serverUrl in serverPathCandidates(candidate)) {
        final info = await probe(serverUrl);
        if (info == null) continue;
        return ServerProbeResult(
          serverUrl: serverUrl,
          serverType: await resolveServerType(info, serverUrl: serverUrl),
          info: info,
        );
      }
    }
    return null;
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

  Future<PublicSystemInfoDTO?> probe(String serverUrl) async {
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
