import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/network/certificate_trust.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/remote_access.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/server_addresses_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../provider_container.dart';

class _MockMediaServerClient extends Mock implements MediaServerClient {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _Hosts implements HttpClientAdapter {
  final status = <String, int>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final code = status[options.uri.host];
    if (code == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'unreachable',
      );
    }
    return ResponseBody.fromString('', code);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const home = 'http://192.168.1.10:8096';
  const remote = 'http://100.64.0.5:8096';
  const relay = 'https://abc.tunnel.jellybox.app';
  const access = RemoteAccessResult(
    access: RemoteAccess(url: relay, fingerprint: 'ab12'),
  );

  late _Hosts hosts;
  late _MockMediaServerClient client;
  late _MockSecureStorage storage;
  late CertificateTrust trust;

  setUp(() {
    hosts = _Hosts();
    client = _MockMediaServerClient();
    storage = _MockSecureStorage();
    trust = CertificateTrust();
    when(() => client.remoteAccess()).thenAnswer((_) async => access);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => storage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});
  });

  ProviderContainer start({
    String? knownRelay,
    String? knownRemote,
    bool signedIn = true,
    Duration heartbeat = const Duration(hours: 1),
  }) {
    final container = createProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        certificateTrustProvider.overrideWithValue(trust),
        mediaServerClientProvider.overrideWithValue(client),
        connectivityProvider.overrideWith(
          (ref) => ConnectivityNotifier(
            ref,
            probeClient: () => Dio()..httpClientAdapter = hosts,
            heartbeat: heartbeat,
          ),
        ),
      ],
    );
    if (signedIn) {
      container.read(currentUserProvider.notifier).state = const User(
        userId: 'u',
        token: 't',
      );
    }
    container.read(baseUrlProvider.notifier).state = home;
    container.read(serverAddressesProvider.notifier).state = ServerAddresses(
      home: home,
      remote: knownRemote,
      relay: knownRelay,
    );
    container.read(dioProvider).httpClientAdapter = hosts;
    container.read(connectivityProvider);
    return container;
  }

  Future<bool> probe(ProviderContainer container) =>
      container.read(connectivityProvider.notifier).refresh();

  test('- stays on the home address while it answers', () async {
    hosts.status['192.168.1.10'] = 200;
    hosts.status['abc.tunnel.jellybox.app'] = 200;
    final container = start(knownRelay: relay);

    expect(await probe(container), isTrue);
    expect(container.read(baseUrlProvider), home);
  });

  test('- falls back to the relay when home does not answer', () async {
    hosts.status['abc.tunnel.jellybox.app'] = 200;
    final container = start(knownRelay: relay);

    expect(await probe(container), isTrue);
    expect(container.read(baseUrlProvider), relay);
  });

  test('- is offline when the relay cannot reach the server either', () async {
    hosts.status['abc.tunnel.jellybox.app'] = 502;
    final container = start(knownRelay: relay);

    expect(await probe(container), isFalse);
    expect(container.read(baseUrlProvider), home);
  });

  test('- goes back home as soon as home answers again', () async {
    hosts.status['abc.tunnel.jellybox.app'] = 200;
    final container = start(knownRelay: relay);
    await probe(container);
    expect(container.read(baseUrlProvider), relay);

    hosts.status['192.168.1.10'] = 200;
    await probe(container);

    expect(container.read(baseUrlProvider), home);
  });

  test('- learns the relay address once sign-in finishes', () async {
    hosts.status['192.168.1.10'] = 200;
    when(() => client.remoteAccess()).thenAnswer((_) async => access);
    final container = start(signedIn: false);
    await probe(container);
    expect(container.read(serverAddressesProvider)?.relay, isNull);

    container.read(currentUserProvider.notifier).state = const User(
      userId: 'u',
      token: 't',
    );
    await pumpEventQueue();

    expect(container.read(serverAddressesProvider)?.relay, relay);
  });

  test('- tells direct, tunnel and offline apart', () async {
    hosts.status['192.168.1.10'] = 200;
    final container = start(knownRelay: relay)
      ..listen(serverConnectionProvider, (_, _) {});

    await probe(container);
    expect(container.read(serverConnectionProvider), ServerConnection.direct);

    hosts.status
      ..remove('192.168.1.10')
      ..['abc.tunnel.jellybox.app'] = 200;
    await probe(container);
    expect(container.read(serverConnectionProvider), ServerConnection.tunnel);

    hosts.status['abc.tunnel.jellybox.app'] = 502;
    await probe(container);
    expect(container.read(serverConnectionProvider), ServerConnection.offline);
  });

  test(
    '- notices home going away on its own, without a network event',
    () async {
      hosts.status['192.168.1.10'] = 200;
      hosts.status['abc.tunnel.jellybox.app'] = 200;
      final container = start(
        knownRelay: relay,
        heartbeat: const Duration(milliseconds: 20),
      );
      await probe(container);
      expect(container.read(baseUrlProvider), home);

      hosts.status.remove('192.168.1.10');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(container.read(baseUrlProvider), relay);
    },
  );

  test('- retries a request that cannot reach home on the tunnel', () async {
    hosts.status['192.168.1.10'] = 200;
    hosts.status['abc.tunnel.jellybox.app'] = 200;
    final container = start(knownRelay: relay);
    await probe(container);
    hosts.status.remove('192.168.1.10');

    final response = await container
        .read(dioProvider)
        .getUri<void>(Uri.parse('$home/Items?limit=5'));

    expect(response.realUri.toString(), '$relay/Items?limit=5');
    expect(container.read(baseUrlProvider), relay);
  });

  test(
    '- leaves a failed request alone once the tunnel is known to be down',
    () async {
      hosts.status['192.168.1.10'] = 200;
      hosts.status['abc.tunnel.jellybox.app'] = 502;
      final container = start(knownRelay: relay);
      await probe(container);
      expect(container.read(relayReachableProvider), isFalse);
      hosts.status.remove('192.168.1.10');

      await expectLater(
        container.read(dioProvider).getUri<void>(Uri.parse('$home/Items')),
        throwsA(isA<DioException>()),
      );
      expect(container.read(baseUrlProvider), home);
    },
  );

  test('- counts a redirect from the tunnel as an answer', () async {
    hosts.status['abc.tunnel.jellybox.app'] = 302;
    final container = start(knownRelay: relay);

    expect(await probe(container), isTrue);
    expect(container.read(relayReachableProvider), isTrue);
    expect(container.read(baseUrlProvider), relay);
  });

  test(
    '- forgets the relay address once the server stops publishing one',
    () async {
      hosts.status['192.168.1.10'] = 200;
      when(() => client.remoteAccess()).thenAnswer((_) async => null);
      final container = start(knownRelay: relay);

      await probe(container);
      await pumpEventQueue();

      expect(container.read(serverAddressesProvider)?.relay, isNull);
      verify(() => storage.delete(key: relayUrlStorageKey)).called(1);
    },
  );

  test('- keeps the relay address when the server cannot be asked', () async {
    hosts.status['192.168.1.10'] = 200;
    when(() => client.remoteAccess()).thenThrow(
      DioException.connectionError(
        requestOptions: RequestOptions(path: '/'),
        reason: 'unreachable',
      ),
    );
    final container = start(knownRelay: relay);

    await probe(container);
    await pumpEventQueue();

    expect(container.read(serverAddressesProvider)?.relay, relay);
  });

  test('- rechecks at once when a request through the tunnel fails', () async {
    hosts.status['abc.tunnel.jellybox.app'] = 200;
    final container = start(knownRelay: relay);
    await probe(container);
    expect(container.read(serverConnectionProvider), ServerConnection.tunnel);

    hosts.status['abc.tunnel.jellybox.app'] = 502;
    await expectLater(
      container.read(dioProvider).getUri<void>(Uri.parse('$relay/Items')),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(serverConnectionProvider), ServerConnection.offline);
  });

  test('- pins the server certificate it learns at home', () async {
    hosts.status['192.168.1.10'] = 200;
    final container = start();

    await probe(container);
    await pumpEventQueue();

    expect(container.read(serverAddressesProvider)?.relay, relay);
    expect(trust.isTrusted('abc.tunnel.jellybox.app', 443), isTrue);
  });

  test('- only takes tunnel addresses on the tunnel domain', () {
    expect(isTunnelAddress(Uri.parse(relay), anyHost: false), isTrue);
    expect(
      isTunnelAddress(Uri.parse('https://evil.example/r/abc'), anyHost: false),
      isFalse,
    );
    expect(
      isTunnelAddress(
        Uri.parse('http://abc.tunnel.jellybox.app'),
        anyHost: false,
      ),
      isFalse,
    );
    expect(
      isTunnelAddress(
        Uri.parse('https://tunnel.jellybox.app.evil.example'),
        anyHost: false,
      ),
      isFalse,
    );
  });

  test(
    '- falls back to the remote address when home does not answer',
    () async {
      hosts.status['100.64.0.5'] = 200;
      final container = start(knownRemote: remote);

      expect(await probe(container), isTrue);
      expect(container.read(baseUrlProvider), remote);
    },
  );

  test('- prefers the remote address over the tunnel', () async {
    hosts.status['100.64.0.5'] = 200;
    hosts.status['abc.tunnel.jellybox.app'] = 200;
    final container = start(knownRemote: remote, knownRelay: relay);

    await probe(container);

    expect(container.read(baseUrlProvider), remote);
    expect(container.read(relayReachableProvider), isTrue);
  });

  test('- takes the tunnel when the remote address is down too', () async {
    hosts.status['abc.tunnel.jellybox.app'] = 200;
    final container = start(knownRemote: remote, knownRelay: relay);

    await probe(container);

    expect(container.read(baseUrlProvider), relay);
  });

  test('- tells a remote connection apart from a direct one', () async {
    hosts.status['100.64.0.5'] = 200;
    final container = start(knownRemote: remote)
      ..listen(serverConnectionProvider, (_, _) {});

    await probe(container);
    expect(container.read(serverConnectionProvider), ServerConnection.remote);

    hosts.status['192.168.1.10'] = 200;
    await probe(container);
    expect(container.read(serverConnectionProvider), ServerConnection.direct);
  });

  test('- walks a failed request from home to remote to tunnel', () async {
    hosts.status['192.168.1.10'] = 200;
    hosts.status['100.64.0.5'] = 200;
    hosts.status['abc.tunnel.jellybox.app'] = 200;
    final container = start(knownRemote: remote, knownRelay: relay);
    await probe(container);
    hosts.status.remove('192.168.1.10');

    final viaRemote = await container
        .read(dioProvider)
        .getUri<void>(Uri.parse('$home/Items?limit=5'));
    expect(viaRemote.realUri.toString(), '$remote/Items?limit=5');
    expect(container.read(baseUrlProvider), remote);

    await probe(container);
    hosts.status.remove('100.64.0.5');
    final viaTunnel = await container
        .read(dioProvider)
        .getUri<void>(Uri.parse('$home/Items?limit=5'));
    expect(viaTunnel.realUri.toString(), '$relay/Items?limit=5');
    expect(container.read(baseUrlProvider), relay);
  });

  test('- skips a fallback the last probe found down', () async {
    hosts.status['192.168.1.10'] = 200;
    hosts.status['abc.tunnel.jellybox.app'] = 200;
    final container = start(knownRemote: remote, knownRelay: relay);
    await probe(container);
    hosts.status.remove('192.168.1.10');

    final response = await container
        .read(dioProvider)
        .getUri<void>(Uri.parse('$home/Items'));

    expect(response.realUri.toString(), '$relay/Items');
  });

  test('- leaves the remote address alone when home answers', () async {
    hosts.status['192.168.1.10'] = 200;
    hosts.status['100.64.0.5'] = 200;
    final container = start(knownRemote: remote);

    final response = await container
        .read(dioProvider)
        .getUri<void>(Uri.parse('$home/Items'));

    expect(response.realUri.toString(), '$home/Items');
  });

  test('- stores the remote address and probes it at once', () async {
    hosts.status['100.64.0.5'] = 200;
    final container = start();
    await probe(container);
    expect(container.read(connectivityProvider), isFalse);

    await container
        .read(connectivityProvider.notifier)
        .setRemote('100.64.0.5:8096');
    await pumpEventQueue();

    verify(
      () => storage.write(key: remoteUrlStorageKey, value: remote),
    ).called(1);
    expect(container.read(serverAddressesProvider)?.remote, remote);
    expect(container.read(baseUrlProvider), remote);
    expect(container.read(connectivityProvider), isTrue);
  });

  test('- forgets the remote address on request', () async {
    final container = start(knownRemote: remote);

    await container.read(connectivityProvider.notifier).setRemote(null);

    verify(() => storage.delete(key: remoteUrlStorageKey)).called(1);
    expect(container.read(serverAddressesProvider)?.remote, isNull);
  });

  test('- remembers why this user was refused a seat', () async {
    hosts.status['192.168.1.10'] = 200;
    when(() => client.remoteAccess()).thenAnswer(
      (_) async => const RemoteAccessResult(denied: 'plan_full'),
    );
    final container = start(knownRelay: relay);

    await probe(container);
    await pumpEventQueue();

    final addresses = container.read(serverAddressesProvider);
    expect(addresses?.relay, isNull);
    expect(addresses?.relayDenied, 'plan_full');
  });
}
