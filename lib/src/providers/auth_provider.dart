import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show PaintingBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/core/network/certificate_trust.dart';
import 'package:jplayer/src/data/backend/media_server_backends.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/media_server_exception.dart';
import 'package:jplayer/src/data/backend/quick_connect.dart';
import 'package:jplayer/src/data/backend/server_auth_headers.dart';
import 'package:jplayer/src/data/backend/server_session.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/forward_cache_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/current_server_type_provider.dart';
import 'package:jplayer/src/providers/session_providers.dart';

class AuthNotifier extends AsyncNotifier<bool?> {
  AuthNotifier() {
    _noAuthNetworkInterceptor = InterceptorsWrapper(
      onError: (error, handler) {
        final failure = MediaServerException.fromDio(error);
        if (failure.isUnauthorized && !_authenticating && !_loggingOut) {
          logout();
        }
        handler.next(error);
      },
    );
  }

  late final Interceptor _noAuthNetworkInterceptor;
  late Dio _client;
  late FlutterSecureStorage _storage;

  bool _authenticating = false;
  bool _loggingOut = false;
  _QuickConnectSession? _quickConnect;

  static const serverUnreachableError =
      'Server is not accessible. Check the server URL and your connection.';
  static const invalidCredentialsError = 'Incorrect login or password';
  static const untrustedCertificateError =
      "The server's security certificate is not trusted.";
  static const quickConnectUnavailableError =
      'Quick Connect is not available on this server.';
  static const quickConnectExpiredError =
      'The Quick Connect code expired. Try again.';
  static const quickConnectCancelled = 'quick-connect-cancelled';

  static const _sessionValidationTimeout = Duration(seconds: 6);
  static const _quickConnectPollInterval = Duration(seconds: 3);
  static const _quickConnectTimeout = Duration(minutes: 5);

  static const _serverUrlKey = 'serverUrl';
  static const _serverTypeKey = 'serverType';
  static const _serverIdKey = 'serverId';
  static const _userIdKey = 'userId';
  static const _authTokenKey = 'authToken';

  static const _legacyAuthTokenKey = 'x-mediabrowser-token';

  @override
  FutureOr<bool?> build() async {
    _client = ref.watch(dioProvider);
    _storage = ref.watch(secureStorageProvider);
    if (!_client.interceptors.contains(_noAuthNetworkInterceptor)) {
      _client.interceptors.add(_noAuthNetworkInterceptor);
    }
    ref.onDispose(() {
      _client.interceptors.remove(_noAuthNetworkInterceptor);
    });

    state = const AsyncLoading();

    final serverUrl = await _storage.read(key: _serverUrlKey);
    ref.read(baseUrlProvider.notifier).state = serverUrl;
    if (serverUrl == null) return false;

    final serverType = _parseServerType(
      await _storage.read(key: _serverTypeKey),
    );
    ref.read(currentServerTypeProvider.notifier).state = serverType;

    final userId = await _storage.read(key: _userIdKey) ?? '';
    final serverId = await _resolveServerId(serverUrl);
    ref.read(currentServerIdProvider.notifier).state = serverId;
    final token = await _migrateAuthToken();
    final client = _clientFor(
      serverType,
      serverUrl: serverUrl,
      userId: userId,
      token: token,
    );
    final status = await _validateSession(client, token, serverType);
    final sessionUsable = status != SessionStatus.invalid;

    if (sessionUsable) {
      ref.read(currentUserProvider.notifier).state = User(
        userId: userId,
        token: token,
      );
      _setAuthHeader(serverType, token);
      if (status == SessionStatus.valid) await _adoptLegacyDownloads();
    }

    return sessionUsable && serverUrl.isNotEmpty && userId.isNotEmpty;
  }

  Future<String?> login(
    UserCredentials credentials, {
    ServerType? serverType,
  }) async {
    final serverUrl = normalizeServerUrl(credentials.serverUrl);
    ref.read(certificateTrustProvider).clearRejections();
    _authenticating = true;
    try {
      final resolved = serverType ?? await _detectServerType(serverUrl);
      return await _signIn(resolved, serverUrl, credentials);
    } finally {
      _authenticating = false;
    }
  }

  Future<ServerType> _detectServerType(String serverUrl) async {
    final detected = await ref
        .read(serverProbeServiceProvider)
        .detectType(serverUrl);
    return detected ?? ServerType.jellyfin;
  }

  Future<String?> _signIn(
    ServerType serverType,
    String serverUrl,
    UserCredentials credentials,
  ) async {
    try {
      _setAuthHeader(serverType);
      final session = await authenticatorFor(
        serverType,
        dio: _client,
      ).signIn(credentials, serverUrl: serverUrl);
      await _establishSession(serverType, serverUrl, session);
    } on DioException catch (e) {
      return _loginErrorMessage(MediaServerException.fromDio(e), serverUrl);
    } on MediaServerException catch (e) {
      return _loginErrorMessage(e, serverUrl);
    }
    return state.error?.toString();
  }

  Future<void> _establishSession(
    ServerType serverType,
    String serverUrl,
    ServerSession session,
  ) async {
    final token = session.token;
    final userId = session.userId;
    final serverId = session.serverId;
    await _storage.write(key: _authTokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _serverUrlKey, value: serverUrl);
    await _storage.write(key: _serverIdKey, value: serverId);
    await _storage.write(key: _serverTypeKey, value: serverType.name);

    ref.read(currentServerIdProvider.notifier).state = serverId;
    ref.read(baseUrlProvider.notifier).state = serverUrl;
    ref.read(currentServerTypeProvider.notifier).state = serverType;
    ref.read(currentUserProvider.notifier).state = User(
      userId: userId,
      token: token,
    );
    final client = _clientFor(
      serverType,
      serverUrl: serverUrl,
      userId: userId,
      token: token,
    );
    final status = await _validateSession(client, token, serverType);
    final sessionUsable = status != SessionStatus.invalid;
    if (sessionUsable) {
      _setAuthHeader(serverType, token);
      await _adoptLegacyDownloads();
    }
    state = AsyncData(sessionUsable);
  }

  Future<QuickConnectRequest?> beginQuickConnect(
    String serverUrl, {
    ServerType? serverType,
  }) async {
    final url = normalizeServerUrl(serverUrl);
    ref.read(certificateTrustProvider).clearRejections();
    _authenticating = true;
    try {
      final resolved = serverType ?? await _detectServerType(url);
      final authenticator = quickConnectFor(resolved, dio: _client);
      if (authenticator == null) {
        _authenticating = false;
        return null;
      }
      _setAuthHeader(resolved);
      final request = await authenticator.initiate(serverUrl: url);
      _quickConnect = _QuickConnectSession(
        authenticator: authenticator,
        serverType: resolved,
        serverUrl: url,
        request: request,
      );
      return request;
    } on Object {
      _authenticating = false;
      _removeAuthHeader();
      return null;
    }
  }

  Future<String?> awaitQuickConnect() async {
    final session = _quickConnect!;
    final deadline = DateTime.now().add(_quickConnectTimeout);
    try {
      while (DateTime.now().isBefore(deadline)) {
        if (session.cancelled) return quickConnectCancelled;
        final failure = await _pollQuickConnect(session);
        if (session.cancelled) return quickConnectCancelled;
        if (session.authorized) return null;
        if (failure != null) return failure;
        await Future<void>.delayed(_quickConnectPollInterval);
      }
      return quickConnectExpiredError;
    } finally {
      if (identical(_quickConnect, session)) _quickConnect = null;
      _authenticating = false;
      if (!session.authorized) _removeAuthHeader();
    }
  }

  Future<String?> _pollQuickConnect(_QuickConnectSession session) async {
    try {
      final result = await session.authenticator.poll(
        session.request,
        serverUrl: session.serverUrl,
      );
      if (result == null) return null;
      session.authorized = true;
      await _establishSession(session.serverType, session.serverUrl, result);
      return null;
    } on DioException catch (e) {
      return _quickConnectErrorMessage(
        MediaServerException.fromDio(e),
        session.serverUrl,
      );
    } on MediaServerException catch (e) {
      return _quickConnectErrorMessage(e, session.serverUrl);
    }
  }

  void cancelQuickConnect() => _quickConnect?.cancelled = true;

  String _quickConnectErrorMessage(MediaServerException e, String serverUrl) {
    if (e.isNotFound || e.isUnauthorized) return quickConnectExpiredError;
    return _loginErrorMessage(e, serverUrl);
  }

  String _loginErrorMessage(MediaServerException e, String serverUrl) {
    if (_rejectedCertificateFor(serverUrl) != null) {
      return untrustedCertificateError;
    }
    return e.isUnauthorized ? invalidCredentialsError : serverUnreachableError;
  }

  ServerCertificate? _rejectedCertificateFor(String serverUrl) {
    final host = Uri.tryParse(serverUrl)?.host;
    if (host == null || host.isEmpty) return null;
    return ref.read(certificateTrustProvider).rejectedFor(host);
  }

  Future<void> logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    state = const AsyncLoading();
    try {
      await _stopPlayback();
      await _purgeQueueCache();
      PaintingBinding.instance.imageCache.clear();
      await Future.wait([
        ref.read(sharedPreferencesProvider).requireValue.clear(),
        _storage.deleteAll(),
        ref.read(certificateTrustProvider).clear(),
        _signOutQuietly(),
      ]);
    } finally {
      _clearSession();
      _removeAuthHeader();
      state = const AsyncData(false);
      _loggingOut = false;
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await ref.read(playbackProvider.notifier).clear();
    } on Object {
      return;
    }
  }

  Future<void> _purgeQueueCache() async {
    try {
      await ref.read(forwardCacheProvider.notifier).cancelPending();
      await ref.read(queueCacheServiceProvider).purge();
    } on Object {
      return;
    }
  }

  Future<String?> _resolveServerId(String serverUrl) async {
    final stored = await _storage.read(key: _serverIdKey);
    if (stored != null && stored.isNotEmpty) return stored;

    // TODO: Remove in 2.5.0, tis is one time thing to adopt dowmloads without serverId

    final identity = await ref
        .read(serverProbeServiceProvider)
        .probe(serverUrl);
    final serverId = identity?.serverId;
    if (serverId == null || serverId.isEmpty) return null;

    await _storage.write(key: _serverIdKey, value: serverId);
    return serverId;
  }

  // TODO: Remove in 2.5.0, tis is one time thing to adopt dowmloads without serverId
  Future<void> _adoptLegacyDownloads() async {
    try {
      await ref.read(downloadDatabaseProvider).adoptLegacyDownloads();
    } on Object {
      return;
    }
  }

  void _clearSession() {
    ref.read(currentUserProvider.notifier).state = null;
    ref.read(baseUrlProvider.notifier).state = null;
    ref.read(currentServerTypeProvider.notifier).state = null;
    ref.read(currentServerIdProvider.notifier).state = null;
    sessionScopedProviders.forEach(ref.invalidate);
  }

  Future<void> _signOutQuietly() async {
    final user = ref.read(currentUserProvider);
    final serverUrl = ref.read(baseUrlProvider);
    if (user == null || serverUrl == null) return;
    try {
      final client = _clientFor(
        ref.read(currentServerTypeProvider) ?? ServerType.jellyfin,
        serverUrl: serverUrl,
        userId: user.userId,
        token: user.token,
      );
      await client.signOut();
    } on Object {
      return;
    }
  }

  MediaServerClient _clientFor(
    ServerType serverType, {
    required String serverUrl,
    required String userId,
    required String token,
  }) => clientFor(
    serverType,
    dio: _client,
    baseUrl: serverUrl,
    userId: userId,
    token: token,
    deviceId: deviceId,
  );

  ServerType _parseServerType(String? stored) =>
      ServerType.values.asNameMap()[stored] ?? ServerType.jellyfin;

  /// TODO: Remove this migration after few releases, when all users would migrate to new token types
  Future<String> _migrateAuthToken() async {
    final token = await _storage.read(key: _authTokenKey);
    if (token != null) return token;

    final legacyToken = await _storage.read(key: _legacyAuthTokenKey);
    if (legacyToken == null) return '';

    await _storage.write(key: _authTokenKey, value: legacyToken);
    return legacyToken;
  }

  Future<SessionStatus> _validateSession(
    MediaServerClient client,
    String? token,
    ServerType serverType,
  ) async {
    if (token == null || token.isEmpty) return SessionStatus.invalid;
    try {
      _setAuthHeader(serverType, token);
      return await client.validateSession().timeout(
        _sessionValidationTimeout,
        onTimeout: () => SessionStatus.unreachable,
      );
    } on Object catch (e) {
      log('Session validation failed: $e', name: 'Auth');
      return SessionStatus.unreachable;
    } finally {
      _removeAuthHeader();
    }
  }

  void _setAuthHeader(ServerType serverType, [String? token]) {
    _removeAuthHeader();
    _client.options.headers.addAll(
      _authHeadersOf(serverType).build(token: token),
    );

    if (kDebugMode) _notifyDeveloper();
  }

  void _removeAuthHeader() {
    for (final serverType in ServerType.values) {
      _authHeadersOf(serverType).managedKeys.forEach(
        _client.options.headers.remove,
      );
    }

    if (kDebugMode) _notifyDeveloper();
  }

  ServerAuthHeaders _authHeadersOf(ServerType serverType) => authHeadersFor(
    serverType,
    deviceId: deviceId,
    deviceName: getCurrentPlatformName(),
    version: version,
  );

  void _notifyDeveloper() => log(
    {
      for (final serverType in ServerType.values)
        for (final key in _authHeadersOf(serverType).managedKeys)
          if (_client.options.headers.containsKey(key))
            key: _client.options.headers[key],
    }.toString(),
    name: 'Auth',
  );
}

class _QuickConnectSession {
  _QuickConnectSession({
    required this.authenticator,
    required this.serverType,
    required this.serverUrl,
    required this.request,
  });

  final QuickConnectAuthenticator authenticator;
  final ServerType serverType;
  final String serverUrl;
  final QuickConnectRequest request;

  bool cancelled = false;
  bool authorized = false;
}

final authProvider = AsyncNotifierProvider<AuthNotifier, bool?>(
  AuthNotifier.new,
);
