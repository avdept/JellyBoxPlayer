import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
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
  const relay = 'https://cloud.jellybox.app/r/abc';

  late _Hosts hosts;
  late _MockMediaServerClient client;
  late _MockSecureStorage storage;

  setUp(() {
    hosts = _Hosts();
    client = _MockMediaServerClient();
    storage = _MockSecureStorage();
    when(() => client.remoteAccessUrl()).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
  });

  ProviderContainer start({
    String? knownRelay,
    bool signedIn = true,
    Duration heartbeat = const Duration(hours: 1),
  }) {
    final container = createProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
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
    hosts.status['cloud.jellybox.app'] = 200;
    final container = start(knownRelay: relay);

    expect(await probe(container), isTrue);
    expect(container.read(baseUrlProvider), home);
  });

  test('- falls back to the relay when home does not answer', () async {
    hosts.status['cloud.jellybox.app'] = 200;
    final container = start(knownRelay: relay);

    expect(await probe(container), isTrue);
    expect(container.read(baseUrlProvider), relay);
  });

  test('- is offline when the relay cannot reach the server either', () async {
    hosts.status['cloud.jellybox.app'] = 502;
    final container = start(knownRelay: relay);

    expect(await probe(container), isFalse);
    expect(container.read(baseUrlProvider), home);
  });

  test('- goes back home as soon as home answers again', () async {
    hosts.status['cloud.jellybox.app'] = 200;
    final container = start(knownRelay: relay);
    await probe(container);
    expect(container.read(baseUrlProvider), relay);

    hosts.status['192.168.1.10'] = 200;
    await probe(container);

    expect(container.read(baseUrlProvider), home);
  });

  test('- learns the relay address once sign-in finishes', () async {
    hosts.status['192.168.1.10'] = 200;
    when(() => client.remoteAccessUrl()).thenAnswer((_) async => relay);
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
      ..['cloud.jellybox.app'] = 200;
    await probe(container);
    expect(container.read(serverConnectionProvider), ServerConnection.tunnel);

    hosts.status['cloud.jellybox.app'] = 502;
    await probe(container);
    expect(container.read(serverConnectionProvider), ServerConnection.offline);
  });

  test(
    '- notices home going away on its own, without a network event',
    () async {
      hosts.status['192.168.1.10'] = 200;
      hosts.status['cloud.jellybox.app'] = 200;
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
    hosts.status['cloud.jellybox.app'] = 200;
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
      hosts.status['cloud.jellybox.app'] = 502;
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
    hosts.status['cloud.jellybox.app'] = 302;
    final container = start(knownRelay: relay);

    expect(await probe(container), isTrue);
    expect(container.read(relayReachableProvider), isTrue);
    expect(container.read(baseUrlProvider), relay);
  });
}
