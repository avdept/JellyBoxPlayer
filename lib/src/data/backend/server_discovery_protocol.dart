import 'dart:convert';
import 'dart:io';

import 'package:jplayer/src/data/services/server_probe_service.dart';

class ServerAnnouncement {
  const ServerAnnouncement({
    required this.id,
    required this.address,
    required this.serverType,
    this.name,
    this.sourceAddress,
  });

  final String id;
  final String address;
  final ServerType serverType;
  final String? name;
  final String? sourceAddress;
}

abstract class ServerDiscoveryProtocol {
  const ServerDiscoveryProtocol();

  ServerType get serverType;

  int get port;

  String get probe;

  ServerAnnouncement? parse(Datagram datagram);
}

ServerAnnouncement? parseMediaBrowserAnnouncement(
  Datagram datagram, {
  required ServerType serverType,
  required int defaultHttpPort,
}) {
  final Object? payload;
  try {
    payload = jsonDecode(utf8.decode(datagram.data));
  } on Object {
    return null;
  }
  if (payload is! Map<String, dynamic>) return null;
  if (!payload.containsKey('Address') && !payload.containsKey('Id')) {
    return null;
  }

  final sender = 'http://${datagram.address.address}:$defaultHttpPort';
  final address = _text(payload['Address']) ?? sender;
  return ServerAnnouncement(
    id: _text(payload['Id']) ?? address,
    address: normalizeServerUrl(address),
    serverType: serverType,
    name: _text(payload['Name']),
    sourceAddress: sender,
  );
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
