import 'package:dio/dio.dart';
import 'package:jplayer/src/data/backend/media_server_backends.dart';
import 'package:jplayer/src/data/backend/server_identity.dart';
import 'package:jplayer/src/data/backend/server_probe.dart';
import 'package:jplayer/src/data/backend/server_type.dart';

export 'package:jplayer/src/data/backend/mediabrowser_probe.dart'
    show embyPathPrefix, serverPathCandidates, serverTypeFromProductName;
export 'package:jplayer/src/data/backend/server_identity.dart';
export 'package:jplayer/src/data/backend/server_type.dart';

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

Dio defaultProbeClient() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    contentType: 'application/json',
  ),
);

class ServerProbeService {
  ServerProbeService({Dio? client, List<ServerProbe>? probes})
    : _probes = probes ?? defaultServerProbes(client ?? defaultProbeClient());

  final List<ServerProbe> _probes;

  Future<ServerIdentity?> discover(String url) async {
    for (final candidate in serverUrlCandidates(url)) {
      for (final probe in _probes) {
        for (final serverUrl in probe.pathCandidates(candidate)) {
          final identity = await probe.identify(serverUrl);
          if (identity != null) return identity;
        }
      }
    }
    return null;
  }

  Future<ServerIdentity?> probe(String serverUrl) async {
    for (final probe in _probes) {
      final identity = await probe.identify(serverUrl);
      if (identity != null) return identity;
    }
    return null;
  }

  Future<ServerType?> detectType(String serverUrl) async {
    for (final probe in _probes) {
      final serverType = await probe.identifyType(serverUrl);
      if (serverType != null) return serverType;
    }
    return null;
  }
}
