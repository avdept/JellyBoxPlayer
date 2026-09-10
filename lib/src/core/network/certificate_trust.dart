import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerCertificate {
  const ServerCertificate({
    required this.host,
    required this.port,
    required this.fingerprint,
    required this.subject,
    required this.issuer,
    required this.validFrom,
    required this.validTo,
  });

  factory ServerCertificate.of(X509Certificate cert, String host, int port) =>
      ServerCertificate(
        host: host,
        port: port,
        fingerprint: sha256.convert(cert.der).toString(),
        subject: cert.subject,
        issuer: cert.issuer,
        validFrom: cert.startValidity,
        validTo: cert.endValidity,
      );

  final String host;
  final int port;
  final String fingerprint;
  final String subject;
  final String issuer;
  final DateTime validFrom;
  final DateTime validTo;

  String get readableFingerprint {
    final pairs = <String>[];
    for (var i = 0; i + 1 < fingerprint.length; i += 2) {
      pairs.add(fingerprint.substring(i, i + 2).toUpperCase());
    }
    return pairs.join(':');
  }

  String get commonName => _commonNameOf(subject) ?? subject;

  String get issuerName => _commonNameOf(issuer) ?? issuer;

  bool get selfSigned => subject == issuer;

  bool get expired => DateTime.now().toUtc().isAfter(validTo.toUtc());

  static String? _commonNameOf(String distinguishedName) {
    for (final part in distinguishedName.split('/')) {
      if (part.startsWith('CN=')) return part.substring(3);
    }
    return null;
  }
}

class CertificateTrust {
  CertificateTrust({SharedPreferences? preferences}) : _prefs = preferences;

  static final CertificateTrust instance = CertificateTrust();

  static const _prefsKey = 'trusted_certificates';

  SharedPreferences? _prefs;
  final Map<String, String> _trusted = {};
  final Map<String, ServerCertificate> _rejected = {};

  Future<void> load(SharedPreferences preferences) async {
    _prefs = preferences;
    _trusted
      ..clear()
      ..addAll(_decode(preferences.getString(_prefsKey)));
  }

  bool allows(X509Certificate cert, String host, int port) =>
      allowsCertificate(ServerCertificate.of(cert, host, port));

  bool allowsCertificate(ServerCertificate certificate) {
    final trusted = _trusted[_keyOf(certificate.host, certificate.port)];
    if (trusted != null && trusted == certificate.fingerprint) {
      _rejected.remove(certificate.host.toLowerCase());
      return true;
    }
    _rejected[certificate.host.toLowerCase()] = certificate;
    return false;
  }

  ServerCertificate? rejectedFor(String host) => _rejected[host.toLowerCase()];

  bool isPinned(String host, int port) =>
      _trusted.containsKey(_keyOf(host, port));

  Future<void> trust(ServerCertificate certificate) async {
    _trusted[_keyOf(certificate.host, certificate.port)] =
        certificate.fingerprint;
    _rejected.remove(certificate.host.toLowerCase());
    await _persist();
  }

  void clearRejections() => _rejected.clear();

  Future<void> clear() async {
    _trusted.clear();
    _rejected.clear();
    await _prefs?.remove(_prefsKey);
  }

  Future<void> _persist() async {
    await _prefs?.setString(_prefsKey, jsonEncode(_trusted));
  }

  String _keyOf(String host, int port) => '${host.toLowerCase()}:$port';

  Map<String, String> _decode(String? stored) {
    if (stored == null || stored.isEmpty) return const {};
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is String) '${entry.key}': entry.value as String,
      };
    } on FormatException {
      return const {};
    }
  }
}

class TrustedCertificateHttpOverrides extends HttpOverrides {
  TrustedCertificateHttpOverrides(this._trust);

  final CertificateTrust _trust;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)..badCertificateCallback = _trust.allows;
}
