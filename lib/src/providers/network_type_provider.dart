import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkType { wifi, cellular }

bool get deviceHasCellular => Platform.isAndroid || Platform.isIOS;

NetworkType? networkTypeFor(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.wifi) ||
      results.contains(ConnectivityResult.ethernet)) {
    return NetworkType.wifi;
  }
  if (results.contains(ConnectivityResult.mobile)) return NetworkType.cellular;
  if (results.every((result) => result == ConnectivityResult.none)) {
    return null;
  }
  return NetworkType.wifi;
}

class NetworkTypeNotifier extends StateNotifier<NetworkType> {
  NetworkTypeNotifier({bool? hasCellular, Connectivity? connectivity})
    : this._(hasCellular ?? deviceHasCellular, connectivity);

  NetworkTypeNotifier._(bool hasCellular, this._connectivity)
    : super(hasCellular ? NetworkType.cellular : NetworkType.wifi) {
    if (hasCellular) _ready = _watch();
  }

  static const _firstReadTimeout = Duration(seconds: 2);

  final Connectivity? _connectivity;
  Future<void> _ready = Future<void>.value();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> get ready => _ready;

  static bool get _bindingReady {
    try {
      WidgetsBinding.instance;
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _watch() async {
    if (!_bindingReady) return;
    try {
      final connectivity = _connectivity ?? Connectivity();
      _subscription = connectivity.onConnectivityChanged.listen(
        _apply,
        onError: (Object error) =>
            debugPrint('[NetworkType] interface stream error: $error'),
      );
      _apply(
        await connectivity.checkConnectivity().timeout(_firstReadTimeout),
      );
    } on Object catch (error) {
      debugPrint('[NetworkType] connection type unavailable: $error');
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final type = networkTypeFor(results);
    if (!mounted || type == null || type == state) return;
    state = type;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

final networkTypeProvider =
    StateNotifierProvider<NetworkTypeNotifier, NetworkType>(
      (ref) => NetworkTypeNotifier(),
    );
