import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/emby/emby_discovery.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_discovery.dart';
import 'package:jplayer/src/data/backend/server_discovery_protocol.dart';
import 'package:jplayer/src/data/services/server_discovery_service.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';

void main() {
  RawDatagramSocket? fakeServer;

  Future<void> startFakeServer(Map<String, String> replies) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    fakeServer = socket;
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      final reply = replies[utf8.decode(datagram.data)];
      if (reply == null) return;
      socket.send(utf8.encode(reply), datagram.address, datagram.port);
    });
  }

  List<ServerDiscoveryProtocol> protocolsOnFakePort() => [
    JellyfinDiscovery(port: fakeServer!.port),
    EmbyDiscovery(port: fakeServer!.port),
  ];

  ServerDiscoveryService serviceUnderTest() => ServerDiscoveryService(
    protocols: protocolsOnFakePort(),
    targets: [InternetAddress.loopbackIPv4],
    localAddresses: () async => [InternetAddress.loopbackIPv4],
  );

  Future<List<ServerAnnouncement>> discover() => serviceUnderTest()
      .discover(
        timeout: const Duration(milliseconds: 600),
        retryInterval: const Duration(milliseconds: 150),
      )
      .toList();

  String announcement({
    required String name,
    required String id,
    required String address,
  }) => jsonEncode({'Address': address, 'Id': id, 'Name': name});

  tearDown(() {
    fakeServer?.close();
    fakeServer = null;
  });

  group('directedBroadcastFor', () {
    test('- derives the subnet broadcast of an interface address', () {
      expect(
        directedBroadcastFor(InternetAddress('192.168.1.118'))?.address,
        '192.168.1.255',
      );
      expect(
        directedBroadcastFor(InternetAddress('172.20.15.251'))?.address,
        '172.20.15.255',
      );
    });

    test('- has none for the wildcard address', () {
      expect(directedBroadcastFor(InternetAddress.anyIPv4), isNull);
    });

    test('- has none for an IPv6 address', () {
      expect(directedBroadcastFor(InternetAddress('::1')), isNull);
    });
  });

  group('ServerDiscoveryService', () {
    test('- finds a server that answers the Jellyfin probe', () async {
      await startFakeServer({
        const JellyfinDiscovery().probe: announcement(
          name: 'Living Room',
          id: 'jf-1',
          address: 'http://192.168.1.10:8096',
        ),
      });

      final found = await discover();

      expect(found, hasLength(1));
      expect(found.single.serverType, ServerType.jellyfin);
      expect(found.single.name, 'Living Room');
      expect(found.single.id, 'jf-1');
      expect(found.single.address, 'http://192.168.1.10:8096');
    });

    test('- finds a server that answers the Emby probe', () async {
      await startFakeServer({
        const EmbyDiscovery().probe: announcement(
          name: 'Basement',
          id: 'emby-1',
          address: 'http://192.168.1.11:8096',
        ),
      });

      final found = await discover();

      expect(found, hasLength(1));
      expect(found.single.serverType, ServerType.emby);
      expect(found.single.name, 'Basement');
    });

    test('- reports both server types when both answer', () async {
      await startFakeServer({
        const JellyfinDiscovery().probe: announcement(
          name: 'Jelly',
          id: 'jf-1',
          address: 'http://192.168.1.10:8096',
        ),
        const EmbyDiscovery().probe: announcement(
          name: 'Emb',
          id: 'emby-1',
          address: 'http://192.168.1.11:8096',
        ),
      });

      final found = await discover();

      expect(
        found.map((server) => server.serverType).toSet(),
        {ServerType.jellyfin, ServerType.emby},
      );
    });

    test('- reports a repeatedly announced server once', () async {
      await startFakeServer({
        const JellyfinDiscovery().probe: announcement(
          name: 'Living Room',
          id: 'jf-1',
          address: 'http://192.168.1.10:8096',
        ),
      });

      final found = await discover();

      expect(found, hasLength(1));
    });

    test('- adds the missing scheme to an announced address', () async {
      await startFakeServer({
        const JellyfinDiscovery().probe: announcement(
          name: 'Living Room',
          id: 'jf-1',
          address: '192.168.1.10:8096',
        ),
      });

      final found = await discover();

      expect(found.single.address, 'http://192.168.1.10:8096');
    });

    test('- falls back to the sender address when none is announced', () async {
      await startFakeServer({
        const JellyfinDiscovery().probe: jsonEncode({
          'Id': 'jf-1',
          'Name': 'Living Room',
        }),
      });

      final found = await discover();

      expect(found.single.address, 'http://127.0.0.1:8096');
    });

    test('- ignores replies that are not server announcements', () async {
      await startFakeServer({
        const JellyfinDiscovery().probe: 'pong',
        const EmbyDiscovery().probe: jsonEncode({
          'Hello': 'there',
        }),
      });

      final found = await discover();

      expect(found, isEmpty);
    });

    test('- survives an interface that cannot reach the target', () async {
      await startFakeServer(const {});
      final found =
          await ServerDiscoveryService(
                protocols: protocolsOnFakePort(),
                targets: [InternetAddress('255.255.255.255')],
                localAddresses: () async => [InternetAddress.loopbackIPv4],
              )
              .discover(
                timeout: const Duration(milliseconds: 400),
                retryInterval: const Duration(milliseconds: 100),
              )
              .toList();

      expect(found, isEmpty);
    });

    test('- probes the subnet broadcast as well as the limited one', () {
      final targets = ServerDiscoveryService(protocols: const [])
          .targetsFor(InternetAddress('192.168.1.118'))
          .map((target) => target.address);

      expect(targets, ['255.255.255.255', '192.168.1.255']);
    });

    test('- probes only the given targets when they are overridden', () {
      final targets = ServerDiscoveryService(
        protocols: const [],
        targets: [InternetAddress.loopbackIPv4],
      ).targetsFor(InternetAddress('192.168.1.118')).map((t) => t.address);

      expect(targets, ['127.0.0.1']);
    });

    test('- keeps answering when another target is unroutable', () async {
      await startFakeServer({
        const JellyfinDiscovery().probe: announcement(
          name: 'Living Room',
          id: 'jf-1',
          address: 'http://192.168.1.10:8096',
        ),
      });

      final found =
          await ServerDiscoveryService(
                protocols: protocolsOnFakePort(),
                targets: [
                  InternetAddress('255.255.255.255'),
                  InternetAddress.loopbackIPv4,
                ],
                localAddresses: () async => [InternetAddress.loopbackIPv4],
              )
              .discover(
                timeout: const Duration(milliseconds: 600),
                retryInterval: const Duration(milliseconds: 150),
              )
              .toList();

      expect(found, hasLength(1));
      expect(found.single.name, 'Living Room');
    });

    test('- completes with nothing when no server answers', () async {
      await startFakeServer(const {});

      final found = await discover();

      expect(found, isEmpty);
    });
  });
}
