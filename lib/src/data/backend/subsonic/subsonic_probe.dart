import 'package:dio/dio.dart';
import 'package:jplayer/src/data/api/subsonic/subsonic_api.dart';
import 'package:jplayer/src/data/backend/server_identity.dart';
import 'package:jplayer/src/data/backend/server_probe.dart';
import 'package:jplayer/src/data/backend/server_type.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_credentials.dart';
import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';

String subsonicProductLabel(String? type) {
  final trimmed = type?.trim() ?? '';
  if (trimmed.isEmpty) return ServerType.subsonic.label;
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

class SubsonicProbe extends ServerProbe {
  const SubsonicProbe(this._client);

  final Dio _client;

  @override
  ServerType get serverType => ServerType.subsonic;

  @override
  List<String> pathCandidates(String serverUrl) => [
    subsonicServerId(serverUrl),
  ];

  @override
  Future<ServerIdentity?> identify(String serverUrl) async {
    final envelope = await _ping(serverUrl);
    if (envelope == null) return null;
    if (envelope.type == null &&
        envelope.serverVersion == null &&
        envelope.version == null) {
      return null;
    }
    return ServerIdentity(
      serverUrl: serverUrl,
      serverType: serverType,
      serverId: subsonicServerId(serverUrl),
      name: subsonicProductLabel(envelope.type),
      version: envelope.serverVersion ?? envelope.version,
      productName: envelope.type,
    );
  }

  @override
  Future<ServerType?> identifyType(String serverUrl) async =>
      (await identify(serverUrl))?.serverType;

  Future<SubsonicEnvelopeDTO?> _ping(String serverUrl) async {
    try {
      final response = await _client.getUri<Object?>(
        SubsonicApi(_client, baseUrl: serverUrl).uri('ping.view'),
        options: Options(responseType: ResponseType.json),
      );
      final envelope = SubsonicApi.envelopeOf(response.data);
      if (envelope == null) return null;
      return SubsonicEnvelopeDTO.fromJson(envelope);
    } on Object {
      return null;
    }
  }
}
