import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/data/backend/remote_access.dart';
import 'package:jplayer/src/data/providers/certificate_trust_provider.dart';
import 'package:jplayer/src/data/providers/secure_storage_provider.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';

@immutable
class ServerAddresses {
  const ServerAddresses({
    required this.home,
    this.remote,
    this.relay,
    this.relayDenied,
    this.pluginNotice,
  });

  final String home;
  final String? remote;
  final String? relay;
  final String? relayDenied;
  final PluginNotice? pluginNotice;

  List<String> get fallbacks => [?remote, ?relay];

  List<String> get candidates => [home, ...fallbacks];

  ServerAddresses copyWith({
    String? Function()? remote,
    String? Function()? relay,
    String? Function()? relayDenied,
    PluginNotice? Function()? pluginNotice,
  }) => ServerAddresses(
    home: home,
    remote: remote == null ? this.remote : remote(),
    relay: relay == null ? this.relay : relay(),
    relayDenied: relayDenied == null ? this.relayDenied : relayDenied(),
    pluginNotice: pluginNotice == null ? this.pluginNotice : pluginNotice(),
  );

  @override
  bool operator ==(Object other) =>
      other is ServerAddresses &&
      other.home == home &&
      other.remote == remote &&
      other.relay == relay &&
      other.relayDenied == relayDenied &&
      other.pluginNotice == pluginNotice;

  @override
  int get hashCode =>
      Object.hash(home, remote, relay, relayDenied, pluginNotice);
}

const relayUrlStorageKey = 'relayUrl';
const remoteUrlStorageKey = 'remoteUrl';

final serverAddressesProvider = StateProvider<ServerAddresses?>((ref) => null);

final dismissedPluginNoticeProvider = StateProvider<PluginNotice?>(
  (ref) => null,
);

final visiblePluginNoticeProvider = Provider<PluginNotice?>((ref) {
  final notice = ref.watch(
    serverAddressesProvider.select((addresses) => addresses?.pluginNotice),
  );
  final dismissed = ref.watch(dismissedPluginNoticeProvider);
  return notice == dismissed ? null : notice;
});

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
  final notice = result?.notice;
  final current = ref.read(serverAddressesProvider);
  if (current != null && current.pluginNotice != notice) {
    ref.read(serverAddressesProvider.notifier).state = current.copyWith(
      pluginNotice: () => notice,
    );
  }
  if (addresses.relay == relay?.url && addresses.relayDenied == denied) return;
  final storage = ref.read(secureStorageProvider);
  if (relay == null) {
    await storage.delete(key: relayUrlStorageKey);
  } else {
    await storage.write(key: relayUrlStorageKey, value: relay.url);
  }
  ref.read(serverAddressesProvider.notifier).state = ref
      .read(serverAddressesProvider)
      ?.copyWith(relay: () => relay?.url, relayDenied: () => denied);
}

Future<void> rememberRemote(Ref ref, String? url) async {
  final addresses = ref.read(serverAddressesProvider);
  if (addresses == null) return;
  final remote = url == null || url.trim().isEmpty
      ? null
      : normalizeServerUrl(url);
  if (remote == addresses.remote) return;
  final storage = ref.read(secureStorageProvider);
  if (remote == null) {
    await storage.delete(key: remoteUrlStorageKey);
  } else {
    await storage.write(key: remoteUrlStorageKey, value: remote);
  }
  ref.read(serverAddressesProvider.notifier).state = addresses.copyWith(
    remote: () => remote,
  );
}
