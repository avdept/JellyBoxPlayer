import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';

final currentServerTypeProvider = StateProvider<ServerType?>((ref) => null);
