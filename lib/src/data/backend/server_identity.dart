import 'package:jplayer/src/data/backend/server_type.dart';

class ServerIdentity {
  const ServerIdentity({
    required this.serverUrl,
    required this.serverType,
    this.serverId,
    this.name,
    this.version,
    this.productName,
    this.quickConnect = false,
    this.alternateApis = const [],
  });

  final String serverUrl;
  final ServerType serverType;
  final String? serverId;
  final String? name;
  final String? version;
  final String? productName;
  final bool quickConnect;
  final List<ServerIdentity> alternateApis;

  ServerIdentity withAlternateApis(List<ServerIdentity> alternateApis) =>
      ServerIdentity(
        serverUrl: serverUrl,
        serverType: serverType,
        serverId: serverId,
        name: name,
        version: version,
        productName: productName,
        quickConnect: quickConnect,
        alternateApis: alternateApis,
      );
}
