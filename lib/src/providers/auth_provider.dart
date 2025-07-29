import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:retrofit/retrofit.dart';

class AuthNotifier extends AsyncNotifier<bool?> {
  AuthNotifier() {
    _noAuthNetworkInterceptor = InterceptorsWrapper(
      onError: (error, handler) {
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) logout();
      },
    );
  }

  late final Interceptor _noAuthNetworkInterceptor;
  late Dio _client;
  late FlutterSecureStorage _storage;
  late JellyfinApi _api;

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

  String normalizeUrl(String url) {
    if (url.startsWith('http')) return url;
    return 'http://$url';
  }

  Future<String?> login(UserCredentials credentials) async {
    // state = const AsyncLoading<bool>();
    final serverUrl = normalizeUrl(credentials.serverUrl);
    _api = JellyfinApi(_client, baseUrl: serverUrl);
    try {
      final response = await _api.signIn(credentials: credentials);
      final token = _getAuthHeaderFromResponse(response);
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userIdKey, value: response.data.id);
      await _storage.write(key: _serverUrlKey, value: serverUrl);

      ref.read(baseUrlProvider.notifier).state = serverUrl;
      ref.read(currentUserProvider.notifier).state = User(
        userId: response.data.id,
        token: token!,
      );
      final tokenValidated = _validateAuthToken(token, response.data.id);
      if (tokenValidated) _setAuthHeader(token);
      state = AsyncData(tokenValidated);
    } on DioException catch (e) {
      return e.error?.toString();
      // state = AsyncError<bool>(e.error!, e.stackTrace);
    }
    return state.error?.toString();
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await Future.wait([
        ref.read(sharedPreferencesProvider).requireValue.clear(),
        _storage.deleteAll(),
      ]);
    } finally {
      _removeAuthHeader();
      state = const AsyncData(false);
    }
  }

  String? _getAuthHeaderFromResponse(HttpResponse<dynamic> response) {
    return response.response.data['AccessToken'] as String?;
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
