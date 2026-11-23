import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optional_features/jellybox_cloud.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/core/telemetry/telemetry.dart';
import 'package:jplayer/src/data/cloud/cloud_host_adapter.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/play_request.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/instant_mix_provider.dart';
import 'package:jplayer/src/domain/providers/on_repeat_provider.dart';
import 'package:jplayer/src/domain/providers/pins_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/resume_points_provider.dart';
import 'package:jplayer/src/domain/providers/sync_hydrator_provider.dart';
import 'package:jplayer/src/domain/providers/todays_playlists_provider.dart';
import 'package:jplayer/src/providers/accounts_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/diagnostics_provider.dart';
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

final deviceNameProvider = Provider<String>((ref) {
  final custom = ref.watch(
    appSettingsProvider.select((settings) => settings[AppSetting.deviceName]),
  );
  final trimmed = custom is String ? custom.trim() : '';
  return trimmed.isEmpty ? continuityDeviceName() : trimmed;
});

final cloudProvider = StateNotifierProvider<CloudNotifier, CloudState>((ref) {
  final notifier = CloudNotifier(ref);
  ref.onDispose(notifier.shutdown);
  return notifier;
});

class CloudNotifier extends StateNotifier<CloudState> {
  CloudNotifier(this._ref) : super(const CloudState()) {
    cloudLog = debugPrint;
    cloudError = (operation, error, stackTrace, data) => unawaited(
      _ref
          .read(diagnosticsProvider)
          .capture(
            error,
            operation: operation,
            stackTrace: stackTrace,
            tags: const {'area': 'link-sync'},
            extra: data,
          ),
    );

    _host = CloudHostAdapter(_ref);
    _cloud = JellyboxCloud<LibraryItem>(host: _host);
    _states = _cloud.states.listen((next) => state = next);

    _ref
      ..listen(conductorUrlProvider, (_, _) => unawaited(_refresh()))
      ..listen(deviceNameProvider, (_, _) => unawaited(_refresh()))
      ..listen(currentUserProvider, (_, next) {
        if (next == null && _ref.read(accountsProvider).isEmpty) {
          _cloud.forgetAccount();
        }
        unawaited(_refresh());
      })
      ..listen(appSettingsProvider, (_, _) => track(const {'k': 'settings'}))
      ..listen(
        playHistoryChangedProvider,
        (_, _) => track(const {'k': 'play_history'}),
      )
      ..listen(
        resumePointsChangedProvider,
        (_, _) => track(const {'k': 'resume_points'}),
      )
      ..listen(pinsProvider, (_, _) => track(const {'k': 'pins'}))
      ..listen(
        instantMixesProvider,
        (_, _) => track(const {'k': 'instant_mixes'}),
      )
      ..listen(
        generatedPlaylistsChangedProvider,
        (_, _) => track(const {'k': 'generated_playlists'}),
      )
      ..listen(isOfflineProvider, (previous, next) {
        if (previous == true && !next) {
          unawaited(track(const {'k': 'settings'}));
          unawaited(_hydrateStubs());
        }
      });

    _watchNetwork();
    _remote = _RemotePlayback(_cloud);
    _playback = _ref.read(playbackProvider.notifier)..remote = _remote;

    unawaited(_cloud.start(benchUrl: _benchUrl()));
  }

  final Ref _ref;

  late final CloudHostAdapter _host;
  late final JellyboxCloud<LibraryItem> _cloud;
  late final _RemotePlayback _remote;
  late final PlaybackNotifier _playback;
  late final StreamSubscription<CloudState> _states;
  StreamSubscription<List<ConnectivityResult>>? _network;
  AppLifecycleListener? _lifecycle;

  bool get available => _cloud.available;

  Future<bool> signIn({
    required String address,
    required String email,
    required String password,
  }) async {
    final signedIn = await _cloud.signIn(
      address: address,
      email: email,
      password: password,
    );
    if (signedIn) Telemetry.integrationConnected('link');
    return signedIn;
  }

  Future<void> signOut() => _cloud.signOut();

  Future<bool> linkDevice({
    required String address,
    required void Function(DeviceLinkStart start) onCode,
  }) async {
    final linked = await _cloud.linkDevice(address: address, onCode: onCode);
    if (linked) Telemetry.integrationConnected('link-code');
    return linked;
  }

  void cancelDeviceLink() => _cloud.cancelDeviceLink();

  Future<String?> approveDevice(String code) => _cloud.approveDevice(code);

  Future<bool> handoffTo(String deviceId) => _cloud.handoffTo(deviceId);

  bool? sameBackend(ConductorDevice device) => _cloud.sameBackend(device);

  Future<void> sendCommand(PlayerCommand command, {Object? value}) =>
      _cloud.sendCommand(command, value: value);

  Future<bool> claimHere() => _cloud.claimHere();

  Future<void> track(Map<String, Object?> event) => _cloud.track(event);

  Future<void> _hydrateStubs() async {
    final hydrator = _ref.read(syncHydratorProvider);
    try {
      if (await hydrator.hydrateResumePoints()) {
        _ref.read(resumePointsChangedProvider.notifier).state++;
      }
      if (await hydrator.hydratePins()) {
        await _ref.read(pinsProvider.notifier).reload();
      }
      if (await hydrator.hydrateInstantMixes()) {
        await _ref.read(instantMixesProvider.notifier).reload();
      }
      if (await hydrator.hydrateGeneratedPlaylists()) {
        _ref
          ..invalidate(todaysPlaylistsProvider)
          ..invalidate(todaysPlaylistSongsProvider);
      }
    } on Object catch (error, stackTrace) {
      cloudError('sync.hydrate', error, stackTrace, const {});
    }
  }

  Future<void> shutdown() async {
    _lifecycle?.dispose();
    if (_playback.remote == _remote) _playback.remote = null;
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

class _RemotePlayback implements RemotePlayback {
  _RemotePlayback(this._cloud);

  final JellyboxCloud<LibraryItem> _cloud;

  @override
  Future<bool> play(PlayRequest request) => _cloud.playOnRenderer(
    itemIds: request.itemIds,
    index: request.index,
    albumId: request.album.id,
    sourceId: request.sourceId,
    position: request.position,
  );

  @override
  Future<bool> enqueue(List<LibraryItem> songs, {required bool playNext}) =>
      _cloud.enqueueOnRenderer(
        itemIds: [for (final song in songs) song.id],
        playNext: playNext,
      );

  @override
  Future<bool> replaceUpcoming(
    List<LibraryItem> songs,
    LibraryItem album, {
    String? sourceId,
  }) => _cloud.replaceUpcomingOnRenderer(
    itemIds: [for (final song in songs) song.id],
    albumId: album.id,
    sourceId: sourceId,
  );

  @override
  Future<bool> move(int from, int to) => _cloud.moveOnRenderer(from, to);

  @override
  Future<bool> remove(int index) => _cloud.removeOnRenderer(index);
}

final playbackArrivedProvider = StateProvider<int>((ref) => 0);

final cloudTrackProvider =
    Provider<Future<void> Function(Map<String, Object?> event)>(
      (ref) =>
          (event) => ref.exists(cloudProvider)
          ? ref.read(cloudProvider.notifier).track(event)
          : Future<void>.value(),
    );

final cloudAvailableProvider = Provider<bool>(
  (ref) => ref.watch(cloudProvider.notifier).available,
);

final remoteSessionOursProvider = Provider<bool>((ref) {
  final queueRef = ref.watch(
    cloudProvider.select((state) => state.remote?.doc.backendRef),
  );
  final ours = ref.watch(currentServerIdProvider);
  return queueRef == null || ours == null || queueRef == ours;
});

final remoteRendererProvider = Provider<ConductorDevice?>((ref) {
  if (!ref.watch(remoteSessionOursProvider)) return null;
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
