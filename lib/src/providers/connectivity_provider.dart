import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/dio_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/server_addresses_provider.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier(
    this._ref, {
    Dio Function()? probeClient,
    Duration heartbeat = const Duration(seconds: 30),
  }) : _probeClient = probeClient,
       _heartbeatInterval = heartbeat,
       _dio = _ref.read(dioProvider),
       super(true) {
    _watchInterface();
    _watchLifecycle();
    _failover = InterceptorsWrapper(onError: _onRequestError);
    _dio.interceptors.add(_failover);
    _ref.listen<String?>(baseUrlProvider, (previous, next) {
      _routeArtwork();
      if (next != null && next.isNotEmpty && next != previous) {
        if (next != _selected) unawaited(refresh());
      }
    });
    _ref.listen<ServerAddresses?>(serverAddressesProvider, (previous, next) {
      _routeArtwork();
      if (next != null && next != previous) unawaited(refresh());
    });
    _routeArtwork();
    _ref.listen<User?>(currentUserProvider, (previous, next) {
      if (previous == null && next != null) unawaited(refresh());
    });
    unawaited(refresh());
  }

  static const _probeTimeout = Duration(seconds: 4);
  static const _relayRecheck = Duration(minutes: 10);

  final Ref _ref;
  final Dio Function()? _probeClient;
  final Dio _dio;
  late final Interceptor _failover;
  final Duration _heartbeatInterval;
  Timer? _heartbeat;
  StreamSubscription<List<ConnectivityResult>>? _interfaceSubscription;
  AppLifecycleListener? _lifecycleListener;
  Future<bool>? _pending;
  String? _selected;
  Set<String> _down = const {};
  DateTime? _relayCheckedAt;

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

  Future<void> setRemote(String? url) => rememberRemote(_ref, url);

  Future<bool> _probe() async {
    final addresses = _addresses;
    if (addresses == null) return state;
    final candidates = addresses.candidates;
    final relay = addresses.relay;
    _keepBeating(addresses.fallbacks.isNotEmpty);

    final client =
        _probeClient?.call() ??
        Dio(
          BaseOptions(
            connectTimeout: _probeTimeout,
            receiveTimeout: _probeTimeout,
            sendTimeout: _probeTimeout,
            validateStatus: (_) => true,
          ),
        );
    try {
      final answers = await Future.wait([
        for (final url in candidates)
          _answers(client, url, relayed: url == relay),
      ]);
      if (!mounted) return false;
      _down = {
        for (final (i, url) in candidates.indexed)
          if (!answers[i]) url,
      };
      _ref.read(relayReachableProvider.notifier).state = relay == null
          ? null
          : !_down.contains(relay);

      final up = candidates.firstWhereOrNull((url) => !_down.contains(url));
      if (up == null) {
        _setOnline(false);
      } else {
        _select(up);
        _setOnline(true);
        if (up != relay) unawaited(_learnRelay());
      }
    } finally {
      client.close(force: true);
    }
    return mounted && state;
  }

  void _keepBeating(bool beating) {
    if (!beating) {
      _heartbeat?.cancel();
      _heartbeat = null;
    } else {
      _heartbeat ??= Timer.periodic(
        _heartbeatInterval,
        (_) => unawaited(refresh()),
      );
    }
  }

  Future<bool> _answers(Dio client, String url, {bool relayed = false}) async {
    try {
      final response = await client.getUri<void>(
        Uri.parse(url),
        options: Options(followRedirects: false, validateStatus: (_) => true),
      );
      return !relayed || (response.statusCode ?? 0) < 500;
    } on Object {
      return false;
    }
  }

  ServerAddresses? get _addresses {
    final addresses = _ref.read(serverAddressesProvider);
    if (addresses != null) return addresses;
    final home = _ref.read(baseUrlProvider);
    return home == null || home.isEmpty ? null : ServerAddresses(home: home);
  }

  Future<void> _onRequestError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final addresses = _ref.read(serverAddressesProvider);
    final relay = addresses?.relay;
    if (relay != null && _tunnelDown(error, relay)) unawaited(refresh());
    final retry = addresses != null && _worthRetrying(error)
        ? _rerouted(error.requestOptions, addresses.candidates)
        : null;
    if (retry == null) {
      handler.next(error);
      return;
    }

    final (next, options) = retry;
    debugPrint('[Connectivity] server unreachable, retrying on $next');
    _select(next);
    _setOnline(true);
    unawaited(refresh());
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  static bool _tunnelDown(DioException error, String relay) =>
      error.requestOptions.uri.toString().startsWith(relay) &&
      switch (error.type) {
        DioExceptionType.badResponse => const {
          502,
          503,
          504,
        }.contains(error.response?.statusCode),
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout => true,
        DioExceptionType.unknown => error.error is SocketException,
        _ => false,
      };

  static bool _worthRetrying(DioException error) => switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout => true,
    DioExceptionType.unknown => error.error is SocketException,
    _ => false,
  };

  (String, RequestOptions)? _rerouted(
    RequestOptions options,
    List<String> candidates,
  ) {
    final request = options.uri.toString();
    final current = candidates.indexWhere(request.startsWith);
    if (current < 0) return null;
    final from = candidates[current];
    final next = candidates
        .skip(current + 1)
        .firstWhereOrNull((url) => !_down.contains(url));
    if (next == null) return null;
    if (options.path.startsWith(from)) {
      return (
        next,
        options.copyWith(path: next + options.path.substring(from.length)),
      );
    }
    if (options.baseUrl.startsWith(from)) {
      return (
        next,
        options.copyWith(
          baseUrl: next + options.baseUrl.substring(from.length),
        ),
      );
    }
    return null;
  }

  void _select(String url) {
    _selected = url;
    if (_ref.read(baseUrlProvider) == url) return;
    debugPrint('[Connectivity] using $url');
    _ref.read(baseUrlProvider.notifier).state = url;
  }

  Future<void> _learnRelay() async {
    if (_ref.read(currentUserProvider) == null) return;
    final checked = _relayCheckedAt;
    if (checked != null && DateTime.now().difference(checked) < _relayRecheck) {
      return;
    }
    _relayCheckedAt = DateTime.now();
    try {
      final access = await _ref.read(mediaServerClientProvider).remoteAccess();
      if (mounted) await rememberRelay(_ref, access);
    } on Object catch (error) {
      debugPrint('[Connectivity] relay lookup failed: $error');
    }
  }

  void _routeArtwork() {
    ArtworkCache.route = ArtworkRoute(
      addresses: _ref.read(serverAddressesProvider)?.candidates ?? const [],
      active: _ref.read(baseUrlProvider),
    );
  }

  void _setOnline(bool online) {
    if (!mounted || state == online) return;
    state = online;
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _dio.interceptors.remove(_failover);
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

final relayReachableProvider = StateProvider<bool?>((ref) => null);

enum ServerConnection { direct, remote, tunnel, offline }

final serverConnectionProvider = Provider<ServerConnection>((ref) {
  if (ref.watch(isOfflineProvider)) return ServerConnection.offline;
  final addresses = ref.watch(serverAddressesProvider);
  final active = ref.watch(baseUrlProvider);
  if (addresses == null || active == null) return ServerConnection.direct;
  if (active == addresses.relay) return ServerConnection.tunnel;
  if (active == addresses.remote) return ServerConnection.remote;
  return ServerConnection.direct;
});
