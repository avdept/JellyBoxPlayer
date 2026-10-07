import 'dart:async';
import 'dart:io';

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
  static const _retriedOnRelay = 'jellyboxRetriedOnRelay';

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

  Future<bool> _probe() async {
    final addresses = _ref.read(serverAddressesProvider);
    final home = addresses?.home ?? _ref.read(baseUrlProvider);
    if (home == null || home.isEmpty) return state;
    final relay = addresses?.relay;
    _keepBeating(relay != null);

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
      final (homeUp, relayUp) = await (
        _answers(client, home),
        relay == null
            ? Future.value(false)
            : _answers(client, relay, relayed: true),
      ).wait;
      if (!mounted) return false;
      _ref.read(relayReachableProvider.notifier).state = relay == null
          ? null
          : relayUp;

      if (homeUp) {
        _select(home);
        _setOnline(true);
        unawaited(_learnRelay());
      } else if (relayUp) {
        _select(relay!);
        _setOnline(true);
      } else {
        _setOnline(false);
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

  Future<void> _onRequestError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final addresses = _ref.read(serverAddressesProvider);
    final relay = addresses?.relay;
    if (relay != null && _tunnelDown(error, relay)) unawaited(refresh());
    final retry = relay != null && _worthRetrying(error)
        ? _onRelay(error.requestOptions, addresses!.home, relay)
        : null;
    if (retry == null) {
      handler.next(error);
      return;
    }

    debugPrint('[Connectivity] home unreachable, retrying on the tunnel');
    _select(relay!);
    _setOnline(true);
    unawaited(refresh());
    try {
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (relayError) {
      handler.next(relayError);
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

  bool _worthRetrying(DioException error) =>
      error.requestOptions.extra[_retriedOnRelay] != true &&
      _ref.read(relayReachableProvider) != false &&
      switch (error.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout => true,
        DioExceptionType.unknown => error.error is SocketException,
        _ => false,
      };

  static RequestOptions? _onRelay(
    RequestOptions options,
    String home,
    String relay,
  ) {
    final extra = {...options.extra, _retriedOnRelay: true};
    if (options.path.startsWith(home)) {
      return options.copyWith(
        path: relay + options.path.substring(home.length),
        extra: extra,
      );
    }
    if (options.baseUrl.startsWith(home)) {
      return options.copyWith(
        baseUrl: relay + options.baseUrl.substring(home.length),
        extra: extra,
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
    final addresses = _ref.read(serverAddressesProvider);
    ArtworkCache.route = ArtworkRoute(
      addresses: [?addresses?.home, ?addresses?.relay],
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

enum ServerConnection { direct, tunnel, offline }

final serverConnectionProvider = Provider<ServerConnection>((ref) {
  if (ref.watch(isOfflineProvider)) return ServerConnection.offline;
  final relay = ref.watch(serverAddressesProvider)?.relay;
  return relay != null && ref.watch(baseUrlProvider) == relay
      ? ServerConnection.tunnel
      : ServerConnection.direct;
});
