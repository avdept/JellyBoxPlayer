import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:retrofit/retrofit.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool?>>((ref) {
  var notifier = AuthNotifier(dioClient: ref.read(dioProvider), secureStorage: ref.read(secureStorageProvider), ref: ref);
  notifier.addNoAuthNetworkInterceptor();
  return notifier;
});

class AuthNotifier extends StateNotifier<AsyncValue<bool?>> {
  AuthNotifier({
    required Dio dioClient,
    required FlutterSecureStorage secureStorage,
    required StateNotifierProviderRef<AuthNotifier, AsyncValue<bool?>> ref,
  })  : _client = dioClient,
        _storage = secureStorage,
        _ref = ref,
        super(const AsyncValue<bool?>.data(false));

  late JellyfinApi _api;
  final Dio _client;
  final FlutterSecureStorage _storage;

  final StateNotifierProviderRef<AuthNotifier, AsyncValue<bool?>> _ref;

  static const _serverUrlKey = 'serverUrl';
  static const _userIdKey = 'userId';
  static const _tokenKey = 'x-mediabrowser-token';

  void addNoAuthNetworkInterceptor() {
    _client.interceptors.add(InterceptorsWrapper(onError: (error, handler) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        logout();
        return;
      }
    }));
  }

  Future<void> checkAuthState() async {
    state = const AsyncLoading();
    final token = await _storage.read(key: _tokenKey);
    final serverUrl = await _storage.read(key: _serverUrlKey);
    final userId = await _storage.read(key: _userIdKey);
    _ref.read(baseUrlProvider.notifier).state = serverUrl;

    if (serverUrl == null) {
      state = const AsyncValue<bool?>.data(false);
      return;
    }
    _api = JellyfinApi(_client, baseUrl: serverUrl);

    final tokenValidated = _validateAuthToken(token, userId ?? '');

    if (tokenValidated) {
      _ref.read(currentUserProvider.notifier).state = User(userId: userId!, token: token!);
      _setAuthHeader(token);
    }
    if (state.value == tokenValidated) return;
    state = AsyncValue<bool>.data(tokenValidated && (serverUrl.isNotEmpty) && (userId?.isNotEmpty ?? false));
  }

  String normalizeUrl(String url) {
    if (!url.startsWith('http')) {
      return 'http://$url';
    }

    return url;
  }

  Future<String?> login(UserCredentials credentials) async {
    // state = const AsyncLoading<bool>();
    final serverUrl = normalizeUrl(credentials.serverUrl);
    _api = JellyfinApi(_client, baseUrl: serverUrl);
    try {
      final response = await _api.signIn(credentials.toJson());
      final token = _getAuthHeaderFromResponse(response);
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userIdKey, value: response.data.id);
      await _storage.write(key: _serverUrlKey, value: serverUrl);

      _ref.read(baseUrlProvider.notifier).state = serverUrl;
      _ref.read(currentUserProvider.notifier).state = User(userId: response.data.id, token: token!);
      final tokenValidated = _validateAuthToken(token, response.data.id);
      if (tokenValidated) _setAuthHeader(token);
      state = AsyncValue<bool>.data(tokenValidated);
    } on DioException catch (e) {
      return e.error?.toString();
      // state = AsyncError<bool>(e.error!, e.stackTrace);
    }
    return state.error?.toString();
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _serverUrlKey);
    await prefs.clear();
    _removeAuthHeader();
    state = const AsyncValue<bool?>.data(false);
  }

  String? _getAuthHeaderFromResponse(HttpResponse<dynamic> response) => response.response.data['AccessToken'] as String;

  bool _validateAuthToken(String? token, String userId) {
    // if (token == null) return false;

    // final tokenPayload = JwtDecoder.decode(token);
    // final exp = tokenPayload['exp'] as int?;

    // if (exp == null) return true;
    var tokenValid = false;
    try {
      _setAuthHeader(token!);
      _api.getArtists(userId: userId);
      tokenValid = true;
      _removeAuthHeader();
    } catch (e) {
      tokenValid = false;
    }

    // final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    // final now = DateTime.now();

    // return expirationTime.isAfter(now);
    return token != null && tokenValid;
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
