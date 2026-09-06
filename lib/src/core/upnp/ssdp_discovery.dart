import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class SsdpResponse {
  const SsdpResponse({
    required this.usn,
    required this.location,
    required this.address,
    this.searchTarget,
    this.server,
  });

  static SsdpResponse? parse(Datagram datagram) {
    final String payload;
    try {
      payload = utf8.decode(datagram.data);
    } on FormatException {
      return null;
    }

    final headers = <String, String>{};
    for (final line in const LineSplitter().convert(payload).skip(1)) {
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      headers[line.substring(0, separator).trim().toUpperCase()] = line
          .substring(separator + 1)
          .trim();
    }

    final location = headers['LOCATION'];
    if (location == null || location.isEmpty) return null;
    final uri = Uri.tryParse(location);
    if (uri == null || !uri.hasScheme) return null;

    return SsdpResponse(
      usn: headers['USN'] ?? location,
      location: uri,
      address: datagram.address,
      searchTarget: headers['ST'] ?? headers['NT'],
      server: headers['SERVER'],
    );
  }

  final String usn;
  final Uri location;
  final InternetAddress address;
  final String? searchTarget;
  final String? server;
}

class SsdpDiscovery {
  SsdpDiscovery({Future<List<InternetAddress>> Function()? localAddresses})
    : _localAddresses = localAddresses ?? defaultLocalAddresses;

  static final multicastAddress = InternetAddress('239.255.255.250');
  static const port = 1900;
  static const mediaRendererTarget =
      'urn:schemas-upnp-org:device:MediaRenderer:1';
  static const allTarget = 'ssdp:all';

  final Future<List<InternetAddress>> Function() _localAddresses;

  Stream<SsdpResponse> search({
    List<String> searchTargets = const [mediaRendererTarget, allTarget],
    Duration timeout = const Duration(seconds: 4),
    Duration retryInterval = const Duration(milliseconds: 900),
  }) => _SsdpSearch(
    localAddresses: _localAddresses,
    searchTargets: searchTargets,
    timeout: timeout,
    retryInterval: retryInterval,
  ).stream;
}

class _SsdpSearch {
  _SsdpSearch({
    required this.localAddresses,
    required this.searchTargets,
    required this.timeout,
    required this.retryInterval,
  }) {
    _controller
      ..onListen = _start
      ..onCancel = _closeSockets;
  }

  final Future<List<InternetAddress>> Function() localAddresses;
  final List<String> searchTargets;
  final Duration timeout;
  final Duration retryInterval;

  final _controller = StreamController<SsdpResponse>();
  final _sockets = <RawDatagramSocket>[];
  final _seen = <String>{};
  Timer? _deadline;
  Timer? _repeat;
  var _stopped = false;

  Stream<SsdpResponse> get stream => _controller.stream;

  Future<void> _start() async {
    try {
      await _openSockets();
      if (_stopped) return;
      if (_sockets.isEmpty) return _finish();
      _announce();
      _repeat = Timer.periodic(retryInterval, (_) => _announce());
      _deadline = Timer(timeout, _finish);
    } on Object {
      await _finish();
    }
  }

  Future<void> _openSockets() async {
    for (final address in await localAddresses()) {
      if (_stopped) return;
      try {
        final socket = await RawDatagramSocket.bind(address, 0);
        _selectMulticastInterface(socket, address);
        socket
          ..multicastHops = 2
          ..listen(
            (event) {
              if (event == RawSocketEvent.read) _receive(socket);
            },
            onError: (Object _) {},
          );
        _sockets.add(socket);
      } on Object {
        continue;
      }
    }
  }

  void _selectMulticastInterface(
    RawDatagramSocket socket,
    InternetAddress address,
  ) {
    if (address.type != InternetAddressType.IPv4) return;
    if (address.address == InternetAddress.anyIPv4.address) return;
    try {
      socket.setRawOption(
        RawSocketOption(
          RawSocketOption.levelIPv4,
          RawSocketOption.IPv4MulticastInterface,
          address.rawAddress,
        ),
      );
    } on Object catch (error) {
      debugPrint('[SSDP] multicast interface ${address.address}: $error');
    }
  }

  void _announce() {
    for (final socket in _sockets) {
      for (final target in searchTargets) {
        final request =
            'M-SEARCH * HTTP/1.1\r\n'
            'HOST: ${SsdpDiscovery.multicastAddress.address}:'
            '${SsdpDiscovery.port}\r\n'
            'MAN: "ssdp:discover"\r\n'
            'MX: 2\r\n'
            'ST: $target\r\n\r\n';
        try {
          socket.send(
            utf8.encode(request),
            SsdpDiscovery.multicastAddress,
            SsdpDiscovery.port,
          );
        } on Object {
          continue;
        }
      }
    }
  }

  void _receive(RawDatagramSocket socket) {
    final datagram = socket.receive();
    if (datagram == null) return;
    final response = SsdpResponse.parse(datagram);
    if (response == null) return;
    if (!_seen.add('${response.usn}|${response.location}')) return;
    if (!_controller.isClosed) _controller.add(response);
  }

  void _closeSockets() {
    _stopped = true;
    _deadline?.cancel();
    _repeat?.cancel();
    for (final socket in _sockets) {
      socket.close();
    }
    _sockets.clear();
  }

  Future<void> _finish() async {
    if (_stopped) return;
    _closeSockets();
    if (!_controller.isClosed) await _controller.close();
  }
}

Future<List<InternetAddress>> defaultLocalAddresses() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    return [for (final interface in interfaces) ...interface.addresses];
  } on Object {
    return [InternetAddress.anyIPv4];
  }
}
