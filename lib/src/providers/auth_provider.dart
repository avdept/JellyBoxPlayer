import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_client.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/current_server_type_provider.dart';

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
  static const _userIdKey = 'userId';
  static const _authTokenKey = 'authToken';

  /// The HTTP header Jellyfin expects its access token under. Distinct from
  /// [_authTokenKey] (the generic secure-storage key), since that header
  /// name is Jellyfin protocol detail, not a storage concern.
  static const _jellyfinAuthHeader = 'x-mediabrowser-token';

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
    final token = await _storage.read(key: _authTokenKey) ?? '';
    final client = _clientFor(
      serverType,
      serverUrl: serverUrl,
      userId: userId,
      token: token,
    );
    final tokenValidated = await _validateSession(client, token);

    if (tokenValidated) {
      ref.read(currentUserProvider.notifier).state = User(
        userId: userId,
        token: token,
      );
      _setAuthHeader(token);
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
      switch (serverType) {
        case ServerType.jellyfin:
          return await _loginJellyfin(serverUrl, credentials);
      }
    } finally {
      _authenticating = false;
    }
  }

  Future<String?> _loginJellyfin(
    String serverUrl,
    UserCredentials credentials,
  ) async {
    final api = JellyfinApi(_client, baseUrl: serverUrl);
    try {
      final response = await api.signIn(credentials: credentials);
      print(response.data.sessionInfo); // TODO: remove after testing
      final token = response.data.accessToken;
      final userId = response.data.user.id;
      await _storage.write(key: _authTokenKey, value: token);
      await _storage.write(key: _userIdKey, value: userId);
      await _storage.write(key: _serverUrlKey, value: serverUrl);
      await _storage.write(
        key: _serverTypeKey,
        value: ServerType.jellyfin.name,
      );

      ref.read(baseUrlProvider.notifier).state = serverUrl;
      ref.read(currentServerTypeProvider.notifier).state =
          ServerType.jellyfin;
      ref.read(currentUserProvider.notifier).state = User(
        userId: userId,
        token: token,
      );
      final client = _clientFor(
        ServerType.jellyfin,
        serverUrl: serverUrl,
        userId: userId,
        token: token,
      );
      final tokenValidated = await _validateSession(client, token);
      if (tokenValidated) _setAuthHeader(token);
      state = AsyncData(tokenValidated);
    } on DioException catch (e) {
      return _loginErrorMessage(e);
    }
    return state.error?.toString();
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
      await Future.wait([
        ref.read(sharedPreferencesProvider).requireValue.clear(),
        _storage.deleteAll(),
        _signOutQuietly(),
      ]);
    } finally {
      ref.invalidate(currentLibraryProvider);
      _removeAuthHeader();
      state = const AsyncData(false);
      _loggingOut = false;
    }
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
    }
  }

  ServerType _parseServerType(String? stored) =>
      ServerType.values.asNameMap()[stored] ?? ServerType.jellyfin;

  Future<bool> _validateSession(MediaServerClient client, String? token) async {
    if (token == null) return false;
    try {
      _setAuthHeader(token);
      final valid = await client.validateSession();
      _removeAuthHeader();
      return valid;
    } catch (e) {
      print('Error validating token: type=${e.runtimeType}, message=$e');
      return false;
    }
  }

  void _setAuthHeader(String token) {
    _client.options.headers[_jellyfinAuthHeader] = token;

    if (kDebugMode) _notifyDeveloper();
  }

  void _removeAuthHeader() {
    _client.options.headers.remove(_jellyfinAuthHeader);

    if (kDebugMode) _notifyDeveloper();
  }

  void _notifyDeveloper() => log(
    _client.options.headers[_jellyfinAuthHeader].toString(),
    name: 'Auth',
  );
}

final authProvider = AsyncNotifierProvider<AuthNotifier, bool?>(
  AuthNotifier.new,
);
