import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/server_discovery_protocol.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_discovery_service.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/domain/providers/discovered_servers_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class MockServerDiscoveryService extends Mock
    implements ServerDiscoveryService {}

class MockServerProbeService extends Mock implements ServerProbeService {}

void main() {
  late MockServerDiscoveryService mockDiscovery;
  late MockServerProbeService mockProbe;

  ServerAnnouncement announcement({
    String id = 'jf-1',
    String address = 'http://192.168.1.10:8096',
    ServerType serverType = ServerType.jellyfin,
    String? name = 'Announced',
    String? sourceAddress,
  }) => ServerAnnouncement(
    id: id,
    address: address,
    serverType: serverType,
    name: name,
    sourceAddress: sourceAddress,
  );

  ServerProbeResult probeResult({
    String serverUrl = 'http://192.168.1.10:8096',
    ServerType serverType = ServerType.jellyfin,
    String? serverName = 'Living Room',
  }) => ServerProbeResult(
    serverUrl: serverUrl,
    serverType: serverType,
    info: PublicSystemInfoDTO(
      id: 'server-id',
      serverName: serverName,
      version: '10.9.11',
    ),
  );

  void announces(List<ServerAnnouncement> announcements) {
    when(() => mockDiscovery.discover()).thenAnswer(
      (_) => Stream.fromIterable(announcements),
    );
  }

  ServerDiscoveryNotifier notifierUnderTest() {
    final container = createProviderContainer(
      overrides: [
        serverDiscoveryServiceProvider.overrideWithValue(mockDiscovery),
        serverProbeServiceProvider.overrideWithValue(mockProbe),
      ],
    )..listen(serverDiscoveryProvider, (_, _) {});
    return container.read(serverDiscoveryProvider.notifier);
  }

  setUp(() {
    mockDiscovery = MockServerDiscoveryService();
    mockProbe = MockServerProbeService();
    announces(const []);
    when(() => mockProbe.discover(any())).thenAnswer((_) async => null);
  });

  group('ServerDiscoveryNotifier', () {
    test('- starts idle', () {
      final notifier = notifierUnderTest();

      expect(notifier.state.scanning, isFalse);
      expect(notifier.state.finished, isFalse);
      expect(notifier.state.servers, isEmpty);
    });

    test('- finishes empty when nothing answers', () async {
      final notifier = notifierUnderTest();

      await notifier.scan();

      expect(notifier.state.scanning, isFalse);
      expect(notifier.state.foundNothing, isTrue);
    });

    test('- keeps only announcements the probe confirms', () async {
      announces([
        announcement(),
        announcement(id: 'jf-2', address: 'http://192.168.1.99:8096'),
      ]);
      when(
        () => mockProbe.discover('http://192.168.1.10:8096'),
      ).thenAnswer((_) async => probeResult());

      final notifier = notifierUnderTest();
      await notifier.scan();

      expect(notifier.state.servers, hasLength(1));
      expect(
        notifier.state.servers.single.serverUrl,
        'http://192.168.1.10:8096',
      );
      expect(notifier.state.finished, isTrue);
    });

    test('- takes the url and type the probe resolved', () async {
      announces([announcement(address: 'http://192.168.1.11:8096')]);
      when(() => mockProbe.discover(any())).thenAnswer(
        (_) async => probeResult(
          serverUrl: 'http://192.168.1.11:8096/emby',
          serverType: ServerType.emby,
        ),
      );

      final notifier = notifierUnderTest();
      await notifier.scan();

      final server = notifier.state.servers.single;
      expect(server.serverUrl, 'http://192.168.1.11:8096/emby');
      expect(server.serverType, ServerType.emby);
    });

    test('- names the server after the system info', () async {
      announces([announcement()]);
      when(
        () => mockProbe.discover(any()),
      ).thenAnswer((_) async => probeResult());

      final notifier = notifierUnderTest();
      await notifier.scan();

      expect(notifier.state.servers.single.name, 'Living Room');
    });

    test('- falls back to the announced name', () async {
      announces([announcement()]);
      when(
        () => mockProbe.discover(any()),
      ).thenAnswer((_) async => probeResult(serverName: null));

      final notifier = notifierUnderTest();
      await notifier.scan();

      expect(notifier.state.servers.single.name, 'Announced');
    });

    test('- falls back to the host when nothing is named', () async {
      announces([announcement(name: null)]);
      when(
        () => mockProbe.discover(any()),
      ).thenAnswer((_) async => probeResult(serverName: null));

      final notifier = notifierUnderTest();
      await notifier.scan();

      expect(notifier.state.servers.single.name, '192.168.1.10');
    });

    test('- lists a server reachable at one url once', () async {
      announces([
        announcement(),
        announcement(id: 'jf-1-again', address: 'http://jelly.local:8096'),
      ]);
      when(
        () => mockProbe.discover(any()),
      ).thenAnswer((_) async => probeResult());

      final notifier = notifierUnderTest();
      await notifier.scan();

      expect(notifier.state.servers, hasLength(1));
    });

    test('- falls back to the sender when the announced url is dead', () async {
      announces([
        announcement(
          address: 'http://172.19.0.13:8096',
          sourceAddress: 'http://192.168.1.118:8096',
        ),
      ]);
      when(
        () => mockProbe.discover('http://172.19.0.13:8096'),
      ).thenAnswer((_) async => null);
      when(() => mockProbe.discover('http://192.168.1.118:8096')).thenAnswer(
        (_) async => probeResult(serverUrl: 'http://192.168.1.118:8096'),
      );

      final notifier = notifierUnderTest();
      await notifier.scan();

      expect(
        notifier.state.servers.single.serverUrl,
        'http://192.168.1.118:8096',
      );
    });

    test('- lists nothing when neither url answers', () async {
      announces([
        announcement(
          address: 'http://172.19.0.13:8096',
          sourceAddress: 'http://192.168.1.118:8096',
        ),
      ]);

      final notifier = notifierUnderTest();
      await notifier.scan();

      expect(notifier.state.servers, isEmpty);
      expect(notifier.state.foundNothing, isTrue);
    });

    test('- drops the results of a scan that was restarted', () async {
      final firstScan = StreamController<ServerAnnouncement>();
      when(() => mockDiscovery.discover()).thenAnswer((_) => firstScan.stream);
      when(
        () => mockProbe.discover(any()),
      ).thenAnswer((_) async => probeResult());

      final notifier = notifierUnderTest();
      final pending = notifier.scan();

      announces(const []);
      await notifier.scan();
      firstScan
        ..add(announcement())
        ..close().ignore();
      await pending;

      expect(notifier.state.servers, isEmpty);
      expect(notifier.state.finished, isTrue);
    });
  });
}
