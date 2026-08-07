import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';

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
  late JellyfinApi _api;

  bool _authenticating = false;
  bool _loggingOut = false;

  static const serverUnreachableError =
      'Server is not accessible. Check the server URL and your connection.';
  static const invalidCredentialsError = 'Incorrect login or password';

  static const _serverUrlKey = 'serverUrl';
  static const _userIdKey = 'userId';
  static const _tokenKey = 'x-mediabrowser-token';

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

    _api = JellyfinApi(_client, baseUrl: serverUrl);
    final userId = await _storage.read(key: _userIdKey) ?? '';
    final token = await _storage.read(key: _tokenKey) ?? '';
    final tokenValidated = _validateAuthToken(token, userId);

    if (tokenValidated) {
      ref.read(currentUserProvider.notifier).state = User(
        userId: userId,
        token: token,
      );
      _setAuthHeader(token);
    }

    return tokenValidated && serverUrl.isNotEmpty && userId.isNotEmpty;
  }

  Future<String?> login(UserCredentials credentials) async {
    // state = const AsyncLoading<bool>();
    final serverUrl = normalizeServerUrl(credentials.serverUrl);
    _api = JellyfinApi(_client, baseUrl: serverUrl);
    _authenticating = true;
    try {
      final response = await _api.signIn(credentials: credentials);
      print(response.data.sessionInfo); // TODO: remove after testing
      final token = response.data.accessToken;
      final userId = response.data.user.id;
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userIdKey, value: userId);
      await _storage.write(key: _serverUrlKey, value: serverUrl);

      ref.read(baseUrlProvider.notifier).state = serverUrl;
      ref.read(currentUserProvider.notifier).state = User(
        userId: userId,
        token: token,
      );
      final tokenValidated = _validateAuthToken(token, userId);
      if (tokenValidated) _setAuthHeader(token);
      state = AsyncData(tokenValidated);
    } on DioException catch (e) {
      return _loginErrorMessage(e);
      // state = AsyncError<bool>(e.error!, e.stackTrace);
    } finally {
      _authenticating = false;
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
    try {
      await _api.signOut();
    } on Object {
      return;
    }
  }

  bool _validateAuthToken(String? token, String userId) {
    if (token == null) return false;

    // final tokenPayload = JwtDecoder.decode(token);
    // final exp = tokenPayload['exp'] as int?;

    // if (exp == null) return true;
    var tokenValid = false;
    try {
      _setAuthHeader(token);
      _api.getArtists(userId: userId);
      tokenValid = true;
      _removeAuthHeader();
    } catch (e) {
      print('Error validating token: type=${e.runtimeType}, message=$e');
      tokenValid = false;
    }

    // final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    // final now = DateTime.now();

    // return expirationTime.isAfter(now);
    return tokenValid;
  }

  void _setAuthHeader(String token) {
    _client.options.headers[_tokenKey] = token;

    if (kDebugMode) _notifyDeveloper();
  }

  void _removeAuthHeader() {
    _client.options.headers.remove(_tokenKey);

    if (kDebugMode) _notifyDeveloper();
  }

  void _notifyDeveloper() => log(
    _client.options.headers[_tokenKey].toString(),
    name: 'Auth',
  );
}

final authProvider = AsyncNotifierProvider<AuthNotifier, bool?>(
  AuthNotifier.new,
);
