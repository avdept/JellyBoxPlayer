import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optional_features/upnp_quirks.dart';

final controlPointHostProvider = Provider<ControlPointHost>((ref) {
  if (Platform.isIOS || Platform.isAndroid) return ControlPointHost.suspending;
  return ControlPointHost.sustained;
});
