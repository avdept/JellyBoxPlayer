import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/network/certificate_trust.dart';

final certificateTrustProvider = Provider<CertificateTrust>(
  (ref) => CertificateTrust.instance,
);
