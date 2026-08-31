import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:jplayer/src/data/backend/server_discovery_protocol.dart';

class ServerDiscoveryService {
  ServerDiscoveryService({
    required List<ServerDiscoveryProtocol> protocols,
    List<InternetAddress>? targets,
    Future<List<InternetAddress>> Function()? localAddresses,
  }) : _protocols = protocols,
       _targets = targets,
       _localAddresses = localAddresses ?? _defaultLocalAddresses;

  static final limitedBroadcast = InternetAddress('255.255.255.255');

  final List<ServerDiscoveryProtocol> _protocols;
  final List<InternetAddress>? _targets;
  final Future<List<InternetAddress>> Function() _localAddresses;

  Stream<ServerAnnouncement> discover({
    Duration timeout = const Duration(seconds: 4),
    Duration retryInterval = const Duration(milliseconds: 900),
  }) => _DiscoveryRun(
    protocols: _protocols,
    localAddresses: _localAddresses,
    targetsFor: targetsFor,
    timeout: timeout,
    retryInterval: retryInterval,
  ).stream;

  List<InternetAddress> targetsFor(InternetAddress address) {
    final overrides = _targets;
    if (overrides != null) return overrides;
    final directed = directedBroadcastFor(address);
    return [limitedBroadcast, ?directed];
  }
}

class _DiscoveryRun {
  _DiscoveryRun({
    required this.protocols,
    required this.localAddresses,
    required this.targetsFor,
    required this.timeout,
    required this.retryInterval,
  }) {
    _controller
      ..onListen = _start
      ..onCancel = _closeSockets;
  }

  final List<ServerDiscoveryProtocol> protocols;
  final Future<List<InternetAddress>> Function() localAddresses;
  final List<InternetAddress> Function(InternetAddress) targetsFor;
  final Duration timeout;
  final Duration retryInterval;

  final _controller = StreamController<ServerAnnouncement>();
  final _probes = <_Probe>[];
  final _seen = <String>{};
  Timer? _deadline;
  Timer? _repeat;
  var _stopped = false;

  Stream<ServerAnnouncement> get stream => _controller.stream;

  Future<void> _start() async {
    try {
      await _openSockets();
      if (_stopped) return;
      if (_probes.isEmpty) return _finish();
      _announce();
      _repeat = Timer.periodic(retryInterval, (_) => _announce());
      _deadline = Timer(timeout, _finish);
    } on Object {
      await _finish();
    }
  }

  Future<void> _openSockets() async {
    for (final address in await localAddresses()) {
      for (final protocol in protocols) {
        for (final target in targetsFor(address)) {
          if (_stopped) return;
          final probe = await _Probe.bind(address, protocol, target, _receive);
          if (probe != null) _probes.add(probe);
        }
      }
    }
  }

  void _announce() {
    for (final probe in _probes) {
      probe.send();
    }
  }

  void _receive(_Probe probe) {
    final datagram = probe.socket.receive();
    if (datagram == null) return;
    final announcement = probe.protocol.parse(datagram);
    if (announcement == null) return;
    final key = '${probe.protocol.serverType.name}|${announcement.id}';
    if (!_seen.add(key)) return;
    if (!_controller.isClosed) _controller.add(announcement);
  }

  void _closeSockets() {
    _stopped = true;
    _deadline?.cancel();
    _repeat?.cancel();
    for (final probe in _probes) {
      probe.socket.close();
    }
    _probes.clear();
  }

  Future<void> _finish() async {
    if (_stopped) return;
    _closeSockets();
    if (!_controller.isClosed) await _controller.close();
  }
}

class _Probe {
  _Probe(this.socket, this.protocol, this.target);

  static Future<_Probe?> bind(
    InternetAddress address,
    ServerDiscoveryProtocol protocol,
    InternetAddress target,
    void Function(_Probe probe) onDatagram,
  ) async {
    try {
      final socket = await RawDatagramSocket.bind(address, 0);
      final probe = _Probe(socket, protocol, target);
      socket
        ..broadcastEnabled = true
        ..listen(
          (event) {
            if (event == RawSocketEvent.read) onDatagram(probe);
          },
          onError: (Object _) {},
        );
      return probe;
    } on Object {
      return null;
    }
  }

  final RawDatagramSocket socket;
  final ServerDiscoveryProtocol protocol;
  final InternetAddress target;

  void send() {
    try {
      socket.send(utf8.encode(protocol.probe), target, protocol.port);
    } on Object {
      return;
    }
  }
}

InternetAddress? directedBroadcastFor(InternetAddress address) {
  if (address.type != InternetAddressType.IPv4) return null;
  if (address.address == InternetAddress.anyIPv4.address) return null;
  final octets = address.address.split('.');
  if (octets.length != 4) return null;
  if (octets.any((octet) => int.tryParse(octet) == null)) return null;
  return InternetAddress('${octets[0]}.${octets[1]}.${octets[2]}.255');
}

Future<List<InternetAddress>> _defaultLocalAddresses() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    return [
      InternetAddress.anyIPv4,
      for (final interface in interfaces) ...interface.addresses,
    ];
  } on Object {
    return [InternetAddress.anyIPv4];
  }
}
