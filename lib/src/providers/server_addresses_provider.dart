import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/secure_storage_provider.dart';

@immutable
class ServerAddresses {
  const ServerAddresses({required this.home, this.relay});

  final String home;
  final String? relay;

  @override
  bool operator ==(Object other) =>
      other is ServerAddresses && other.home == home && other.relay == relay;

  @override
  int get hashCode => Object.hash(home, relay);
}

const relayUrlStorageKey = 'relayUrl';

final serverAddressesProvider = StateProvider<ServerAddresses?>((ref) => null);

Future<void> rememberRelayUrl(Ref ref, String? relay) async {
  final addresses = ref.read(serverAddressesProvider);
  if (addresses == null || addresses.relay == relay) return;
  final storage = ref.read(secureStorageProvider);
  if (relay == null) {
    await storage.delete(key: relayUrlStorageKey);
  } else {
    await storage.write(key: relayUrlStorageKey, value: relay);
  }
  ref.read(serverAddressesProvider.notifier).state = ServerAddresses(
    home: addresses.home,
    relay: relay,
  );
}
