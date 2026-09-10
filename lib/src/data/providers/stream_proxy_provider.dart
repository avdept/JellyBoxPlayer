import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/network/stream_proxy_server.dart';
import 'package:jplayer/src/data/providers/certificate_trust_provider.dart';

final streamProxyProvider = Provider<StreamProxyServer>((ref) {
  final trust = ref.watch(certificateTrustProvider);
  final proxy = StreamProxyServer(
    shouldProxy: (uri) =>
        uri.isScheme('https') && trust.isPinned(uri.host, uri.port),
  );
  ref.onDispose(proxy.close);
  return proxy;
});
