import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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
    Duration offlineGrace = const Duration(seconds: 2),
  }) : _probeClient = probeClient,
       _heartbeatInterval = heartbeat,
       _offlineGrace = offlineGrace,
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
      if (previous?.home != next?.home) _forgetServer();
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
  static const _probeIdle = Duration(seconds: 50);
  static const _relayRecheck = Duration(minutes: 10);

  final Ref _ref;
  final Dio Function()? _probeClient;
  final Dio _dio;
  late final Interceptor _failover;
  final Duration _heartbeatInterval;
  final Duration _offlineGrace;
  Timer? _heartbeat;
  StreamSubscription<List<ConnectivityResult>>? _interfaceSubscription;
  AppLifecycleListener? _lifecycleListener;
  Future<bool>? _pending;
  bool _rerun = false;
  Dio? _prober;
  String? _selected;
  Set<String> _down = const {};
  DateTime? _relayCheckedAt;
  DateTime? _suspectedOfflineAt;
  Timer? _offlineConfirm;

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
    final pending = _pending;
    if (pending != null) {
      _rerun = true;
      return pending;
    }
    return _pending = _rounds().whenComplete(() => _pending = null);
  }

  Future<bool> _rounds() async {
    var result = await _probe();
    while (_rerun && mounted) {
      _rerun = false;
      result = await _probe();
    }
    return result;
  }

  Future<void> setRemote(String? url) => rememberRemote(_ref, url);

  List<String> liveEndpoints() {
    final addresses = _addresses;
    if (addresses == null) return const [];
    final candidates = addresses.candidates;
    final selected = [
      _selected,
      _ref.read(baseUrlProvider),
    ].firstWhere(candidates.contains, orElse: () => addresses.home)!;
    final others = addresses.candidates.where((url) => url != selected);
    return [
      selected,
      ...others.where((url) => !_down.contains(url)),
      ...others.where(_down.contains),
    ];
  }

  void _forgetServer() {
    _selected = null;
    _down = const {};
    _relayCheckedAt = null;
    _dismissOfflineSuspicion();
  }

  void _dismissOfflineSuspicion() {
    _suspectedOfflineAt = null;
    _offlineConfirm?.cancel();
    _offlineConfirm = null;
  }

  void adopt(String url) {
    if (!mounted || !(_addresses?.candidates.contains(url) ?? false)) return;
    if (url == _selected) return;
    debugPrint('[Connectivity] a stream got through on $url');
    _select(url);
    _setOnline(true);
    unawaited(refresh());
  }

  Future<bool> _probe() async {
    final addresses = _addresses;
    if (addresses == null) return state;
    final started = DateTime.now();
    final candidates = addresses.candidates;
    final relay = addresses.relay;
    _keepBeating(addresses.fallbacks.isNotEmpty);

    final client = _prober ??= _buildProber();
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
    String verdict(String url) {
      final host = Uri.tryParse(url)?.host ?? url;
      return '$host ${_down.contains(url) ? 'down' : 'up'}';
    }

    debugPrint('[Connectivity] probe: ${candidates.map(verdict).join(', ')}');
    if (up == null) {
      _settleOffline(started);
    } else {
      _dismissOfflineSuspicion();
      _select(up);
      _setOnline(true);
      if (up != relay) unawaited(_learnRelay());
    }
    return mounted && state;
  }

  Dio _buildProber() {
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
    final adapter = client.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () => HttpClient()..idleTimeout = _probeIdle;
    }
    return client;
  }

  void _settleOffline(DateTime started) {
    final suspected = _suspectedOfflineAt;
    if (!state ||
        _offlineGrace == Duration.zero ||
        (suspected != null && started.difference(suspected) >= _offlineGrace)) {
      _setOnline(false);
      return;
    }
    _suspectedOfflineAt ??= started;
    _offlineConfirm ??= Timer(_offlineGrace, () {
      _offlineConfirm = null;
      if (mounted) unawaited(refresh());
    });
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
      final status = response.statusCode ?? 0;
      if (status == 401 || status == 403) return false;
      return !relayed || status < 500;
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
    DioExceptionType.badResponse => const {
      401,
      403,
    }.contains(error.response?.statusCode),
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
    debugPrint('[Connectivity] now ${online ? 'online' : 'offline'}');
    state = online;
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _offlineConfirm?.cancel();
    _prober?.close(force: true);
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
