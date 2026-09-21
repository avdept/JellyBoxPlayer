import 'dart:async';

import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/cast/cast_runtime.dart';

class CastDiscoveryState {
  const CastDiscoveryState({this.devices = const [], this.scanning = false});

  final List<GoogleCastDevice> devices;
  final bool scanning;
}

class CastDevicesNotifier extends StateNotifier<CastDiscoveryState> {
  CastDevicesNotifier() : super(const CastDiscoveryState());

  static const _settleDelay = Duration(seconds: 6);

  StreamSubscription<List<GoogleCastDevice>>? _subscription;
  Timer? _settle;

  void start() {
    if (!castSupported || _subscription != null) return;

    state = CastDiscoveryState(devices: state.devices, scanning: true);
    _subscription = GoogleCastDiscoveryManager.instance.devicesStream.listen(
      (devices) {
        if (!mounted) return;
        state = CastDiscoveryState(
          devices: _sorted(devices),
          scanning: state.scanning,
        );
      },
    );
    unawaited(GoogleCastDiscoveryManager.instance.startDiscovery());

    _settle?.cancel();
    _settle = Timer(_settleDelay, () {
      if (!mounted) return;
      state = CastDiscoveryState(devices: state.devices);
    });
  }

  void stop() {
    if (_subscription == null) return;
    _settle?.cancel();
    _settle = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(GoogleCastDiscoveryManager.instance.stopDiscovery());
  }

  void refresh() {
    if (_subscription == null) {
      start();
      return;
    }
    if (!mounted) return;
    state = CastDiscoveryState(devices: state.devices, scanning: true);
    unawaited(GoogleCastDiscoveryManager.instance.startDiscovery());
    _settle?.cancel();
    _settle = Timer(_settleDelay, () {
      if (!mounted) return;
      state = CastDiscoveryState(devices: state.devices);
    });
  }

  List<GoogleCastDevice> _sorted(List<GoogleCastDevice> devices) => [...devices]
    ..sort(
      (a, b) =>
          a.friendlyName.toLowerCase().compareTo(b.friendlyName.toLowerCase()),
    );

  @override
  void dispose() {
    _settle?.cancel();
    unawaited(_subscription?.cancel());
    if (_subscription != null) {
      unawaited(GoogleCastDiscoveryManager.instance.stopDiscovery());
    }
    super.dispose();
  }
}

final castDevicesProvider =
    StateNotifierProvider<CastDevicesNotifier, CastDiscoveryState>(
      (ref) => CastDevicesNotifier(),
    );
