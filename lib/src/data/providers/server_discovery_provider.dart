import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/emby/emby_discovery.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_discovery.dart';
import 'package:jplayer/src/data/services/server_discovery_service.dart';

final serverDiscoveryServiceProvider = Provider<ServerDiscoveryService>(
  (ref) => ServerDiscoveryService(
    protocols: const [JellyfinDiscovery(), EmbyDiscovery()],
  ),
);
