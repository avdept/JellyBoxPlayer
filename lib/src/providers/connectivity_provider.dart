import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier(this._ref) : super(true) {
    _watchInterface();
    _watchLifecycle();
    _ref.listen<String?>(baseUrlProvider, (previous, next) {
      if (next != null && next.isNotEmpty && next != previous) {
        unawaited(refresh());
      }
    });
    unawaited(refresh());
  }

  static const _probeTimeout = Duration(seconds: 4);

  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _interfaceSubscription;
  AppLifecycleListener? _lifecycleListener;
  Future<bool>? _pending;

  static bool get _bindingReady {
    try {
      WidgetsBinding.instance;
      return true;
    } on Object {
      return false;
    }
  }

  void _watchInterface() {
    if (!_bindingReady) return;
    try {
      _interfaceSubscription = Connectivity().onConnectivityChanged.listen(
        (_) => unawaited(refresh()),
        onError: (Object error) =>
            debugPrint('[Connectivity] interface stream error: $error'),
      );
    } on Object catch (error) {
      debugPrint('[Connectivity] interface events unavailable: $error');
    }
  }

  void _watchLifecycle() {
    if (!_bindingReady) return;
    try {
      _lifecycleListener = AppLifecycleListener(
        onResume: () => unawaited(refresh()),
      );
    } on Object catch (error) {
      debugPrint('[Connectivity] lifecycle events unavailable: $error');
    }
  }

  Future<bool> refresh() {
    return _pending ??= _probe().whenComplete(() => _pending = null);
  }

  Future<bool> _probe() async {
    final serverUrl = _ref.read(baseUrlProvider);
    if (serverUrl == null || serverUrl.isEmpty) return state;

    final client = Dio(
      BaseOptions(
        connectTimeout: _probeTimeout,
        receiveTimeout: _probeTimeout,
        sendTimeout: _probeTimeout,
        validateStatus: (_) => true,
      ),
    );
    try {
      await client.getUri<void>(
        Uri.parse(serverUrl).replace(path: 'System/Info/Public'),
      );
      _setOnline(true);
    } on Object {
      _setOnline(false);
    } finally {
      client.close(force: true);
    }
    return state;
  }

  void _setOnline(bool online) {
    if (!mounted || state == online) return;
    state = online;
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    unawaited(_interfaceSubscription?.cancel());
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);

final isOfflineProvider = Provider<bool>(
  (ref) => !ref.watch(connectivityProvider),
);
