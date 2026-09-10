import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/network/certificate_trust.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late CertificateTrust trust;

  ServerCertificate certificate({
    String host = 'jelly.local',
    int port = 8920,
    String fingerprint = 'aa11',
  }) => ServerCertificate(
    host: host,
    port: port,
    fingerprint: fingerprint,
    subject: '/CN=jelly.local',
    issuer: '/CN=jelly.local',
    validFrom: DateTime.utc(DateTime.now().year),
    validTo: DateTime.utc(DateTime.now().year + 1),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    trust = CertificateTrust();
    await trust.load(prefs);
  });

  test('rejects an unknown certificate and remembers it for the host', () {
    expect(trust.allowsCertificate(certificate()), isFalse);
    expect(trust.rejectedFor('JELLY.local')?.fingerprint, 'aa11');
  });

  test('allows a certificate after it is trusted', () async {
    trust.allowsCertificate(certificate());
    await trust.trust(certificate());

    expect(trust.allowsCertificate(certificate()), isTrue);
    expect(trust.rejectedFor('jelly.local'), isNull);
  });

  test('rejects a different certificate on a trusted host', () async {
    await trust.trust(certificate());

    expect(trust.allowsCertificate(certificate(fingerprint: 'bb22')), isFalse);
    expect(trust.rejectedFor('jelly.local')?.fingerprint, 'bb22');
  });

  test('rejects a trusted certificate served on another port', () async {
    await trust.trust(certificate());

    expect(trust.allowsCertificate(certificate(port: 443)), isFalse);
  });

  test('restores trusted certificates from storage', () async {
    await trust.trust(certificate());

    final restored = CertificateTrust();
    await restored.load(prefs);

    expect(restored.allowsCertificate(certificate()), isTrue);
  });

  test('clear forgets trusted certificates', () async {
    await trust.trust(certificate());
    await trust.clear();

    final restored = CertificateTrust();
    await restored.load(prefs);

    expect(restored.allowsCertificate(certificate()), isFalse);
  });

  test('exposes readable certificate details', () {
    final cert = certificate(fingerprint: 'a1b2c3');

    expect(cert.readableFingerprint, 'A1:B2:C3');
    expect(cert.commonName, 'jelly.local');
    expect(cert.issuerName, 'jelly.local');
    expect(cert.selfSigned, isTrue);
  });
}
