import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show PaintingBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/backend/emby/emby_client.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_client.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/current_server_type_provider.dart';
import 'package:jplayer/src/providers/session_providers.dart';

class AuthNotifier extends AsyncNotifier<bool?> {
  AuthNotifier() {
    _noAuthNetworkInterceptor = InterceptorsWrapper(
      onError: (error, handler) {
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 && !_authenticating && !_loggingOut) logout();
        handler.next(error);
      },
    );
  }

  late final Interceptor _noAuthNetworkInterceptor;
  late Dio _client;
  late FlutterSecureStorage _storage;

  bool _authenticating = false;
  bool _loggingOut = false;

  static const serverUnreachableError =
      'Server is not accessible. Check the server URL and your connection.';
  static const invalidCredentialsError = 'Incorrect login or password';

  static const _serverUrlKey = 'serverUrl';
  static const _serverTypeKey = 'serverType';
  static const _serverIdKey = 'serverId';
  static const _userIdKey = 'userId';
  static const _authTokenKey = 'authToken';

  static const _jellyfinAuthHeader = 'x-mediabrowser-token';
  static const _embyAuthHeader = 'x-emby-token';

  static const _legacyAuthTokenKey = _jellyfinAuthHeader;

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
    final tokenValidated = await _validateSession(client, token, serverType);

    if (tokenValidated) {
      ref.read(currentUserProvider.notifier).state = User(
        userId: userId,
        token: token,
      );
      _setAuthHeader(serverType, token);
      await _adoptLegacyDownloads();
    }

    return tokenValidated && serverUrl.isNotEmpty && userId.isNotEmpty;
  }

  Future<String?> login(
    UserCredentials credentials, {
    ServerType serverType = ServerType.jellyfin,
  }) async {
    final serverUrl = normalizeServerUrl(credentials.serverUrl);
    _authenticating = true;
    try {
      return await _signIn(serverType, serverUrl, credentials);
    } finally {
      _authenticating = false;
    }
  }

  Future<String?> _signIn(
    ServerType serverType,
    String serverUrl,
    UserCredentials credentials,
  ) async {
    try {
      final result = await _authenticate(serverType, serverUrl, credentials);
      final token = result.accessToken;
      final userId = result.user.id;
      final serverId = result.serverId.isNotEmpty ? result.serverId : serverUrl;
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
      final tokenValidated = await _validateSession(client, token, serverType);
      if (tokenValidated) {
        _setAuthHeader(serverType, token);
        await _adoptLegacyDownloads();
      }
      state = AsyncData(tokenValidated);
    } on DioException catch (e) {
      return _loginErrorMessage(e);
    }
    return state.error?.toString();
  }

  Future<SignInResultDTO> _authenticate(
    ServerType serverType,
    String serverUrl,
    UserCredentials credentials,
  ) async {
    switch (serverType) {
      case ServerType.jellyfin:
        final response = await JellyfinApi(
          _client,
          baseUrl: serverUrl,
        ).signIn(credentials: credentials);
        return response.data;

      case ServerType.emby:
        final response = await EmbyApi(
          _client,
          baseUrl: serverUrl,
        ).signIn(credentials: credentials);
        return response.data;
    }
  }

  String _loginErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return invalidCredentialsError;
        }
        return serverUnreachableError;

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return serverUnreachableError;
    }
  }

  Future<void> logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    state = const AsyncLoading();
    try {
      await _stopPlayback();
      PaintingBinding.instance.imageCache.clear();
      await Future.wait([
        ref.read(sharedPreferencesProvider).requireValue.clear(),
        _storage.deleteAll(),
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

  Future<String?> _resolveServerId(String serverUrl) async {
    final stored = await _storage.read(key: _serverIdKey);
    if (stored != null && stored.isNotEmpty) return stored;

    // TODO: Remove in 2.5.0, tis is one time thing to adopt dowmloads without serverId

    final info = await ref.read(serverProbeServiceProvider).probe(serverUrl);
    final serverId = info?.id;
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
  }) {
    switch (serverType) {
      case ServerType.jellyfin:
        return JellyfinClient(
          dio: _client,
          baseUrl: serverUrl,
          userId: userId,
          token: token,
          deviceId: deviceId,
        );

      case ServerType.emby:
        return EmbyClient(
          dio: _client,
          baseUrl: serverUrl,
          userId: userId,
          token: token,
          deviceId: deviceId,
        );
    }
  }

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

  Future<bool> _validateSession(
    MediaServerClient client,
    String? token,
    ServerType serverType,
  ) async {
    if (token == null) return false;
    try {
      _setAuthHeader(serverType, token);
      final valid = await client.validateSession();
      _removeAuthHeader();
      return valid;
    } catch (e) {
      print('Error validating token: type=${e.runtimeType}, message=$e');
      return false;
    }
  }

  void _setAuthHeader(ServerType serverType, String token) {
    _removeAuthHeader();
    _client.options.headers[_authHeaderOf(serverType)] = token;

    if (kDebugMode) _notifyDeveloper();
  }

  void _removeAuthHeader() {
    _client.options.headers
      ..remove(_jellyfinAuthHeader)
      ..remove(_embyAuthHeader);

    if (kDebugMode) _notifyDeveloper();
  }

  String _authHeaderOf(ServerType serverType) => switch (serverType) {
    ServerType.jellyfin => _jellyfinAuthHeader,
    ServerType.emby => _embyAuthHeader,
  };

  void _notifyDeveloper() => log(
    (_client.options.headers[_jellyfinAuthHeader] ??
            _client.options.headers[_embyAuthHeader])
        .toString(),
    name: 'Auth',
  );
}

final authProvider = AsyncNotifierProvider<AuthNotifier, bool?>(
  AuthNotifier.new,
);
