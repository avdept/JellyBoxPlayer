import 'dart:async';

import 'package:flutter/foundation.dart';
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

    unawaited(_cloud.start(benchUrl: _benchUrl()));
  }

  final Ref _ref;

  late final CloudHostAdapter _host;
  late final JellyboxCloud<LibraryItem> _cloud;
  late final StreamSubscription<CloudState> _states;

  bool get available => _cloud.available;

  Future<bool> signIn({
    required String address,
    required String email,
    required String password,
  }) => _cloud.signIn(address: address, email: email, password: password);

  Future<void> signOut() => _cloud.signOut();

  Future<void> handoffTo(String deviceId) => _cloud.handoffTo(deviceId);

  Future<void> claimHere() => _cloud.claimHere();

  Future<void> shutdown() async {
    await _states.cancel();
    await _cloud.dispose();
    _host.dispose();
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

final remoteTrackIdProvider = Provider<String?>((ref) {
  final state = ref.watch(cloudProvider);
  if (state.remoteRenderer == null) return null;
  return state.remote?.doc.currentItemId;
});

final remoteNowPlayingProvider = FutureProvider<LibraryItem?>((ref) async {
  final itemId = ref.watch(remoteTrackIdProvider);
  if (itemId == null) return null;

  final items = await ref.read(mediaServerClientProvider).getItemsByIds([
    itemId,
  ]);
  return items.isEmpty ? null : items.first;
});
