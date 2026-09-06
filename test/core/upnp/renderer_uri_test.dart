import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/upnp/renderer_uri.dart';

void main() {
  test('- swaps a hostname for its LAN address', () async {
    var lookups = 0;
    final resolver = RendererUriResolver(
      lookup: (host) async {
        lookups++;
        expect(host, 'jellyfin.home');
        return [InternetAddress('192.168.1.118')];
      },
    );

    final resolved = await resolver.resolve(
      Uri.parse('http://jellyfin.home:8096/Audio/x/universal?ApiKey=k'),
    );

    expect(
      '$resolved',
      'http://192.168.1.118:8096/Audio/x/universal?ApiKey=k',
    );

    await resolver.resolve(Uri.parse('http://jellyfin.home:8096/Audio/y'));
    expect(lookups, 1, reason: 'the lookup is cached per host');
  });

  test('- leaves an address literal alone', () async {
    final resolver = RendererUriResolver(
      lookup: (_) async => fail('should not look up an IP literal'),
    );

    final uri = Uri.parse('http://192.168.1.118:8096/Audio/x');
    expect(await resolver.resolve(uri), uri);
  });

  test('- prefers IPv4 over IPv6', () async {
    final resolver = RendererUriResolver(
      lookup: (_) async => [
        InternetAddress('fe80::1'),
        InternetAddress('192.168.1.118'),
      ],
    );

    final resolved = await resolver.resolve(
      Uri.parse('http://jellyfin.home:8096/Audio/x'),
    );
    expect(resolved.host, '192.168.1.118');
  });

  test('- keeps the original url when the lookup fails', () async {
    final resolver = RendererUriResolver(
      lookup: (_) async => throw const SocketException('no dns'),
    );

    final uri = Uri.parse('http://jellyfin.home:8096/Audio/x');
    expect(await resolver.resolve(uri), uri);
  });
}
