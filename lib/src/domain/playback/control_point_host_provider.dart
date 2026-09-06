import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upnp_quirks/upnp_quirks.dart';

final controlPointHostProvider = Provider<ControlPointHost>((ref) {
  if (Platform.isIOS || Platform.isAndroid) return ControlPointHost.suspending;
  return ControlPointHost.sustained;
});
