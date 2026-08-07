import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';

final serverProbeServiceProvider = Provider<ServerProbeService>(
  (ref) => ServerProbeService(),
);
