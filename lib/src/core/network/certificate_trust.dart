import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:jplayer/src/config/constants.dart';
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
  static const _pinsKey = 'pinned_certificates';

  SharedPreferences? _prefs;
  final Map<String, String> _trusted = {};
  final Map<String, String> _pins = {};
  final Map<String, ServerCertificate> _rejected = {};

  Future<void> load(SharedPreferences preferences) async {
    _prefs = preferences;
    _trusted
      ..clear()
      ..addAll(_decode(preferences.getString(_prefsKey)));
    _pins
      ..clear()
      ..addAll(_decode(preferences.getString(_pinsKey)));
  }

  bool allows(X509Certificate cert, String host, int port) =>
      allowsCertificate(ServerCertificate.of(cert, host, port));

  bool allowsCertificate(ServerCertificate certificate) {
    final pin = _pins[_keyOf(certificate.host, certificate.port)];
    if (pin != null) return pin == certificate.fingerprint;
    if (isTrusted(certificate.host, certificate.port)) {
      _rejected.remove(certificate.host.toLowerCase());
      return true;
    }
    _rejected[certificate.host.toLowerCase()] = certificate;
    return false;
  }

  ServerCertificate? rejectedFor(String host) => _rejected[host.toLowerCase()];

  bool isTrusted(String host, int port) =>
      _trusted.containsKey(_keyOf(host, port)) ||
      _pins.containsKey(_keyOf(host, port));

  Future<void> trust(ServerCertificate certificate) async {
    _trusted[_keyOf(certificate.host, certificate.port)] =
        certificate.fingerprint;
    _rejected.remove(certificate.host.toLowerCase());
    await _persist();
  }

  String? pinFor(String host, int port) => _pins[_keyOf(host, port)];

  bool matchesPin(X509Certificate cert, String host, int port) =>
      pinFor(host, port) == sha256.convert(cert.der).toString();

  Future<void> pin(String host, int port, String fingerprint) async {
    final key = _keyOf(host, port);
    if (_pins[key] == fingerprint.toLowerCase()) return;
    _pins[key] = fingerprint.toLowerCase();
    await _persist();
  }

  Future<void> unpin(String host, int port) async {
    if (_pins.remove(_keyOf(host, port)) != null) await _persist();
  }

  void clearRejections() => _rejected.clear();

  Future<void> clear() async {
    _trusted.clear();
    _pins.clear();
    _rejected.clear();
    await _prefs?.remove(_prefsKey);
    await _prefs?.remove(_pinsKey);
  }

  Future<void> _persist() async {
    await _prefs?.setString(_prefsKey, jsonEncode(_trusted));
    await _prefs?.setString(_pinsKey, jsonEncode(_pins));
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
  final SecurityContext _noRoots = SecurityContext();

  static int portOf(Uri uri) {
    if (uri.port != 0) return uri.port;
    return uri.isScheme('https') ? 443 : 80;
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)
        ..maxConnectionsPerHost = connectionsPerHost
        ..badCertificateCallback = _trust.allows
        ..connectionFactory = (uri, proxyHost, proxyPort) {
          if (proxyHost != null) {
            return Socket.startConnect(proxyHost, proxyPort!);
          }
          final port = portOf(uri);
          if (!uri.isScheme('https')) {
            return Socket.startConnect(uri.host, port);
          }
          final pinned = _trust.pinFor(uri.host, port) != null;
          return SecureSocket.startConnect(
            uri.host,
            port,
            context: pinned ? _noRoots : context,
            onBadCertificate: (cert) => pinned
                ? _trust.matchesPin(cert, uri.host, port)
                : _trust.allows(cert, uri.host, port),
          );
        };
}
