import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optional_features/jellybox_cloud.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/data/cloud/cloud_host_adapter.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final conductorUrlProvider =
    StateNotifierProvider<ConductorUrlNotifier, String>((ref) {
      return ConductorUrlNotifier(
        ref.watch(sharedPreferencesProvider).valueOrNull,
      );
    });

class ConductorUrlNotifier extends StateNotifier<String> {
  ConductorUrlNotifier(this._prefs)
    : super(
        kDebugMode
            ? (_prefs?.getString(_key) ?? jellyboxCloudUrl)
            : jellyboxCloudUrl,
      );

  static const _key = 'conductor_url';

  final SharedPreferences? _prefs;

  String get url => state;

  set url(String value) {
    if (!kDebugMode) return;
    state = value.trim();
    final prefs = _prefs;
    if (prefs != null) unawaited(prefs.setString(_key, state));
  }
}

final cloudProvider = StateNotifierProvider<CloudNotifier, CloudState>((ref) {
  final notifier = CloudNotifier(ref);
  ref.onDispose(notifier.shutdown);
  return notifier;
});

class CloudNotifier extends StateNotifier<CloudState> {
  CloudNotifier(this._ref) : super(const CloudState()) {
    cloudLog = debugPrint;

    _host = CloudHostAdapter(_ref);
    _cloud = JellyboxCloud<LibraryItem>(host: _host);
    _states = _cloud.states.listen((next) => state = next);

    _ref
      ..listen(conductorUrlProvider, (_, _) => unawaited(_refresh()))
      ..listen(currentUserProvider, (_, next) {
        if (next == null) _cloud.forgetAccount();
        unawaited(_refresh());
      });

    _watchNetwork();

    unawaited(_cloud.start(benchUrl: _benchUrl()));
  }

  final Ref _ref;

  late final CloudHostAdapter _host;
  late final JellyboxCloud<LibraryItem> _cloud;
  late final StreamSubscription<CloudState> _states;
  StreamSubscription<List<ConnectivityResult>>? _network;
  AppLifecycleListener? _lifecycle;

  bool get available => _cloud.available;

  Future<bool> signIn({
    required String address,
    required String email,
    required String password,
  }) => _cloud.signIn(address: address, email: email, password: password);

  Future<void> signOut() => _cloud.signOut();

  Future<void> handoffTo(String deviceId) => _cloud.handoffTo(deviceId);

  Future<void> sendCommand(PlayerCommand command, {Object? value}) =>
      _cloud.sendCommand(command, value: value);

  Future<bool> claimHere() => _cloud.claimHere();

  Future<void> shutdown() async {
    _lifecycle?.dispose();
    await _network?.cancel();
    await _states.cancel();
    await _cloud.dispose();
    _host.dispose();
  }

  void _watchNetwork() {
    try {
      _network = Connectivity().onConnectivityChanged.listen(
        (results) {
          if (results.every((r) => r == ConnectivityResult.none)) return;
          unawaited(_cloud.networkChanged());
        },
        onError: (Object error) =>
            debugPrint('[conductor] network events unavailable: $error'),
      );
    } on Object catch (error) {
      debugPrint('[conductor] network events unavailable: $error');
    }

    try {
      _lifecycle = AppLifecycleListener(
        onResume: () => unawaited(_cloud.networkChanged()),
      );
    } on Object catch (error) {
      debugPrint('[conductor] lifecycle events unavailable: $error');
    }
  }

  Future<void> _refresh() => _cloud.refresh(benchUrl: _benchUrl());

  String? _benchUrl() {
    if (!kDebugMode) return null;
    final url = _ref.read(conductorUrlProvider);
    return url.isEmpty || url == jellyboxCloudUrl ? null : url;
  }
}

final cloudAvailableProvider = Provider<bool>(
  (ref) => ref.watch(cloudProvider.notifier).available,
);

final remoteRendererProvider = Provider<ConductorDevice?>((ref) {
  final state = ref.watch(cloudProvider);
  final hasQueue = !(state.remote?.doc.isEmpty ?? true);
  return hasQueue ? state.remoteRenderer : null;
});

final remoteSessionProvider = Provider<RemoteSession?>(
  (ref) => ref.watch(remoteRendererProvider) == null
      ? null
      : ref.watch(cloudProvider.select((state) => state.remote)),
);

final playingElsewhereProvider = Provider<bool>(
  (ref) => ref.watch(remoteRendererProvider) != null,
);

final remoteQueueProvider = FutureProvider<List<LibraryItem>>((ref) async {
  final key = ref.watch(
    remoteSessionProvider.select((remote) => remote?.doc.itemIds.join(',')),
  );
  if (key == null || key.isEmpty) return const [];

  final ids = key.split(',');
  final items = await ref.read(mediaServerClientProvider).getItemsByIds(ids);
  final byId = {for (final item in items) item.id: item};
  return [
    for (final id in ids)
      byId[id] ??
          LibraryItem(id: id, name: 'Unavailable track', kind: ItemKind.song),
  ];
});

final remoteNowPlayingProvider = Provider<LibraryItem?>((ref) {
  final itemId = ref.watch(
    remoteSessionProvider.select((remote) => remote?.doc.currentItemId),
  );
  if (itemId == null) return null;
  final queue = ref.watch(remoteQueueProvider).valueOrNull ?? const [];
  for (final item in queue) {
    if (item.id == itemId) return item;
  }
  return null;
});

final AutoDisposeStreamProvider<int> _remoteTickProvider =
    StreamProvider.autoDispose<int>((ref) {
      final playing = ref.watch(
        remoteSessionProvider.select((remote) => remote?.doc.playing ?? false),
      );
      if (!playing) return Stream.value(0);
      return Stream.periodic(const Duration(milliseconds: 250), (tick) => tick);
    });

final AutoDisposeProvider<Duration> remotePositionProvider =
    Provider.autoDispose<Duration>((ref) {
      ref.watch(_remoteTickProvider);
      final remote = ref.watch(remoteSessionProvider);
      if (remote == null) return Duration.zero;
      return remote.positionAt(DateTime.now());
    });
