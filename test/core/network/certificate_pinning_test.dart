import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/core/network/certificate_trust.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const cert = 'test/fixtures/tunnel_cert.pem';
  const key = 'test/fixtures/tunnel_key.pem';
  const ca = 'test/fixtures/ca_cert.pem';
  const otherCert = 'test/fixtures/other_cert.pem';

  late HttpServer server;
  late CertificateTrust trust;
  late TrustedCertificateHttpOverrides overrides;
  late Future<void> Function(HttpRequest request) handle;

  String fingerprintOf(String pem) {
    final body = File(
      pem,
    ).readAsLinesSync().where((line) => !line.startsWith('-----')).join();
    return sha256.convert(base64Decode(body)).toString();
  }

  SecurityContext trusting(String pem) =>
      SecurityContext()..setTrustedCertificates(pem);

  Future<int> fetch(SecurityContext? context) async {
    final client = overrides.createHttpClient(context);
    try {
      final request = await client.getUrl(
        Uri.https('127.0.0.1:${server.port}', '/'),
      );
      return (await request.close()).statusCode;
    } finally {
      client.close(force: true);
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    trust = CertificateTrust();
    await trust.load(await SharedPreferences.getInstance());
    overrides = TrustedCertificateHttpOverrides(trust);
    server =
        await HttpServer.bindSecure(
            InternetAddress.loopbackIPv4,
            0,
            SecurityContext()
              ..useCertificateChain(cert)
              ..usePrivateKey(key),
          )
          ..listen((request) => handle(request));
    handle = (request) => request.response.close();
  });

  tearDown(() => server.close(force: true));

  test('a websocket URL without a port connects on the default port', () {
    expect(
      TrustedCertificateHttpOverrides.portOf(
        Uri(scheme: 'https', host: 'cloud.jellybox.app', port: 0),
      ),
      443,
    );
    expect(
      TrustedCertificateHttpOverrides.portOf(
        Uri(scheme: 'http', host: 'jelly.local', port: 0),
      ),
      80,
    );
    expect(
      TrustedCertificateHttpOverrides.portOf(
        Uri.https('jelly.local:8920', '/'),
      ),
      8920,
    );
  });

  test(
    '- a certificate from a trusted authority is enough without a pin',
    () async {
      expect(await fetch(trusting(ca)), 200);
    },
  );

  test('- a pinned host is refused on any other certificate, even one from a '
      'trusted authority', () async {
    await trust.pin('127.0.0.1', server.port, fingerprintOf(otherCert));

    await expectLater(
      fetch(trusting(ca)),
      throwsA(isA<HandshakeException>()),
    );
  });

  test('- a pinned host is accepted on exactly its certificate', () async {
    await trust.pin('127.0.0.1', server.port, fingerprintOf(cert));

    expect(await fetch(null), 200);
  });

  test(
    '- an untrusted certificate still goes through the usual trust',
    () async {
      await expectLater(fetch(null), throwsA(isA<HandshakeException>()));
      final rejected = trust.rejectedFor('127.0.0.1')!;
      await trust.trust(rejected);

      expect(await fetch(null), 200);
    },
  );

  test('- a host never has more than six connections open at once', () async {
    await trust.pin('127.0.0.1', server.port, fingerprintOf(cert));
    var open = 0;
    var peak = 0;
    handle = (request) async {
      open++;
      peak = peak > open ? peak : open;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      open--;
      await request.response.close();
    };

    final client = overrides.createHttpClient(null);
    try {
      final statuses = await Future.wait([
        for (var i = 0; i < 12; i++)
          client
              .getUrl(Uri.https('127.0.0.1:${server.port}', '/$i'))
              .then((request) => request.close())
              .then(
                (response) =>
                    response.drain<void>().then((_) => response.statusCode),
              ),
      ]);
      expect(statuses, everyElement(200));
    } finally {
      client.close(force: true);
    }

    expect(peak, inInclusiveRange(2, connectionsPerHost));
  });
}
