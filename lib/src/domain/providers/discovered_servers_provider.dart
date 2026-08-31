import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/server_discovery_protocol.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_discovery_service.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';

class DiscoveredServer {
  const DiscoveredServer({
    required this.id,
    required this.name,
    required this.serverUrl,
    required this.serverType,
  });

  final String id;
  final String name;
  final String serverUrl;
  final ServerType serverType;
}

class ServerDiscoveryState {
  const ServerDiscoveryState({
    this.scanning = false,
    this.finished = false,
    this.servers = const [],
  });

  final bool scanning;
  final bool finished;
  final List<DiscoveredServer> servers;

  bool get foundNothing => finished && servers.isEmpty;

  ServerDiscoveryState copyWith({
    bool? scanning,
    bool? finished,
    List<DiscoveredServer>? servers,
  }) => ServerDiscoveryState(
    scanning: scanning ?? this.scanning,
    finished: finished ?? this.finished,
    servers: servers ?? this.servers,
  );
}

class ServerDiscoveryNotifier extends StateNotifier<ServerDiscoveryState> {
  ServerDiscoveryNotifier({
    required ServerDiscoveryService discovery,
    required ServerProbeService probe,
  }) : _discovery = discovery,
       _probe = probe,
       super(const ServerDiscoveryState());

  final ServerDiscoveryService _discovery;
  final ServerProbeService _probe;

  StreamSubscription<ServerAnnouncement>? _subscription;
  Completer<void>? _done;
  int _generation = 0;

  Future<void> scan() async {
    final generation = ++_generation;
    await _subscription?.cancel();
    _completeDone();
    state = const ServerDiscoveryState(scanning: true);

    final resolving = <Future<void>>[];
    final done = _done = Completer<void>();
    _subscription = _discovery.discover().listen(
      (announcement) => resolving.add(_resolve(announcement, generation)),
      onError: (Object _) => _completeDone(),
      onDone: _completeDone,
    );

    await done.future;
    await Future.wait(resolving);
    if (generation != _generation || !mounted) return;
    state = state.copyWith(scanning: false, finished: true);
  }

  Future<void> _resolve(ServerAnnouncement announcement, int generation) async {
    final result =
        await _probe.discover(announcement.address) ??
        await _probeSourceAddress(announcement);
    if (result == null || generation != _generation || !mounted) return;
    if (state.servers.any((server) => server.serverUrl == result.serverUrl)) {
      return;
    }

    final server = DiscoveredServer(
      id: announcement.id,
      name:
          result.info.serverName ??
          announcement.name ??
          Uri.parse(result.serverUrl).host,
      serverUrl: result.serverUrl,
      serverType: result.serverType,
    );
    state = state.copyWith(servers: [...state.servers, server]);
  }

  void cancel() {
    _generation++;
    unawaited(_subscription?.cancel());
    _completeDone();
    if (!mounted) return;
    state = state.copyWith(scanning: false, finished: true);
  }

  Future<ServerProbeResult?> _probeSourceAddress(
    ServerAnnouncement announcement,
  ) async {
    final source = announcement.sourceAddress;
    if (source == null || source == announcement.address) return null;
    return _probe.discover(source);
  }

  void _completeDone() {
    final done = _done;
    if (done != null && !done.isCompleted) done.complete();
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_subscription?.cancel());
    _completeDone();
    super.dispose();
  }
}

final AutoDisposeStateNotifierProvider<
  ServerDiscoveryNotifier,
  ServerDiscoveryState
>
serverDiscoveryProvider =
    StateNotifierProvider.autoDispose<
      ServerDiscoveryNotifier,
      ServerDiscoveryState
    >(
      (ref) => ServerDiscoveryNotifier(
        discovery: ref.watch(serverDiscoveryServiceProvider),
        probe: ref.watch(serverProbeServiceProvider),
      ),
    );
