import 'package:dio/dio.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';

String normalizeServerUrl(String url) {
  final trimmed = url.trim();
  if (RegExp('^https?://', caseSensitive: false).hasMatch(trimmed)) {
    return trimmed;
  }
  return 'http://$trimmed';
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
