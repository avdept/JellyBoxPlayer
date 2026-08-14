import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';

/// Which backend the active server session belongs to. Set by `AuthNotifier`
/// on login/session restore; read by `mediaServerClientProvider` to decide
/// which `MediaServerClient` implementation to build.
final currentServerTypeProvider = StateProvider<ServerType?>((ref) => null);
