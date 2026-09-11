import 'package:jplayer/src/data/backend/server_identity.dart';
import 'package:jplayer/src/data/backend/server_type.dart';

abstract class ServerProbe {
  const ServerProbe();

  ServerType get serverType;

  List<String> pathCandidates(String serverUrl);

  Future<ServerIdentity?> identify(String serverUrl);

  Future<ServerType?> identifyType(String serverUrl);
}
