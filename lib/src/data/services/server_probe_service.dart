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

class ServerProbeResult {
  const ServerProbeResult({required this.serverUrl, required this.info});

  final String serverUrl;
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
      final info = await probe(candidate);
      if (info != null) {
        return ServerProbeResult(serverUrl: candidate, info: info);
      }
    }
    return null;
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
