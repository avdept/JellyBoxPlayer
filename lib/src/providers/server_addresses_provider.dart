import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/data/backend/remote_access.dart';
import 'package:jplayer/src/data/providers/certificate_trust_provider.dart';
import 'package:jplayer/src/data/providers/secure_storage_provider.dart';

@immutable
class ServerAddresses {
  const ServerAddresses({required this.home, this.relay, this.relayDenied});

  final String home;
  final String? relay;
  final String? relayDenied;

  @override
  bool operator ==(Object other) =>
      other is ServerAddresses &&
      other.home == home &&
      other.relay == relay &&
      other.relayDenied == relayDenied;

  @override
  int get hashCode => Object.hash(home, relay, relayDenied);
}

const relayUrlStorageKey = 'relayUrl';

final serverAddressesProvider = StateProvider<ServerAddresses?>((ref) => null);

bool isTunnelAddress(Uri uri, {bool anyHost = kDebugMode}) =>
    uri.isScheme('https') &&
    (anyHost || uri.host.endsWith('.$jellyboxTunnelDomain'));

Future<void> rememberRelay(Ref ref, RemoteAccessResult? result) async {
  final addresses = ref.read(serverAddressesProvider);
  if (addresses == null) return;
  final access = result?.access;
  final uri = access == null ? null : Uri.tryParse(access.url);
  final relay = uri != null && isTunnelAddress(uri) ? access : null;

  final trust = ref.read(certificateTrustProvider);
  final previous = Uri.tryParse(addresses.relay ?? '');
  if (previous != null &&
      previous.host.isNotEmpty &&
      previous.host != uri?.host) {
    await trust.unpin(previous.host, previous.port);
  }
  if (relay != null) {
    await trust.pin(uri!.host, uri.port, relay.fingerprint);
  }

  final denied = relay == null ? result?.denied : null;
  if (addresses.relay == relay?.url && addresses.relayDenied == denied) return;
  final storage = ref.read(secureStorageProvider);
  if (relay == null) {
    await storage.delete(key: relayUrlStorageKey);
  } else {
    await storage.write(key: relayUrlStorageKey, value: relay.url);
  }
  ref.read(serverAddressesProvider.notifier).state = ServerAddresses(
    home: addresses.home,
    relay: relay?.url,
    relayDenied: denied,
  );
}
