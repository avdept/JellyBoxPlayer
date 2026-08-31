import 'dart:io';

import 'package:jplayer/src/data/backend/server_discovery_protocol.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';

class EmbyDiscovery extends ServerDiscoveryProtocol {
  const EmbyDiscovery({this.port = 7359, this.httpPort = 8096});

  @override
  final int port;

  final int httpPort;

  @override
  ServerType get serverType => ServerType.emby;

  @override
  String get probe => 'who is EmbyServer?';

  @override
  ServerAnnouncement? parse(Datagram datagram) => parseMediaBrowserAnnouncement(
    datagram,
    serverType: serverType,
    defaultHttpPort: httpPort,
  );
}
