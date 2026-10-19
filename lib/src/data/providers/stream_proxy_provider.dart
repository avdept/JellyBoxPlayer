import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/network/stream_proxy_server.dart';
import 'package:jplayer/src/data/providers/certificate_trust_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

final streamProxyProvider = Provider<StreamProxyServer>((ref) {
  final trust = ref.watch(certificateTrustProvider);
  final proxy = StreamProxyServer(
    shouldProxy: (uri) =>
        uri.isScheme('https') && trust.isTrusted(uri.host, uri.port),
    endpoints: () => ref.read(connectivityProvider.notifier).liveEndpoints(),
    onEndpointSwitched: (url) =>
        ref.read(connectivityProvider.notifier).adopt(url),
  );
  ref.onDispose(proxy.close);
  return proxy;
});
