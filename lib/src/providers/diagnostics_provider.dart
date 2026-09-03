import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/diagnostics/diagnostics.dart';

final diagnosticsProvider = Provider<Diagnostics>((ref) => const Diagnostics());
