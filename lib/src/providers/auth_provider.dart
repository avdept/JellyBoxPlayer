import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:retrofit/retrofit.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool?>>(
  (ref) => AuthNotifier(usersApi: ref.watch(jellyfinApiProvider), dioClient: ref.watch(dioProvider), secureStorage: ref.watch(secureStorageProvider), ref: ref),
);

class AuthNotifier extends StateNotifier<AsyncValue<bool?>> {
  AuthNotifier({
    required JellyfinApi usersApi,
    required Dio dioClient,
    required FlutterSecureStorage secureStorage,
    required StateNotifierProviderRef<AuthNotifier, AsyncValue<bool?>> ref,
  })  : _api = usersApi,
        _client = dioClient,
        _storage = secureStorage,
        _ref = ref,
        super(const AsyncValue<bool?>.data(null));

  JellyfinApi _api;
  final Dio _client;
  final FlutterSecureStorage _storage;
  final StateNotifierProviderRef<AuthNotifier, AsyncValue<bool?>> _ref;

  static const _serverUrlKey = 'serverUrl';
  static const _userIdKey = 'userId';
  static const _tokenKey = 'x-mediabrowser-token';
  static const _emailKey = 'email';

  Future<void> checkAuthState() async {
    state = const AsyncLoading();
    final token = await _storage.read(key: _tokenKey);
    final serverUrl = await _storage.read(key: _serverUrlKey);
    final userId = await _storage.read(key: _userIdKey);
    _ref.read(baseUrlProvider.notifier).state = serverUrl;
    _ref.read(currentUserProvider.notifier).state = userId;
    final tokenValidated = _validateAuthToken(token);
    if (tokenValidated) _setAuthHeader(token!);
    if (serverUrl?.isNotEmpty ?? false) _setServerUrl(serverUrl!);
    if (state.value == tokenValidated) return;
    state = AsyncValue<bool?>.data(tokenValidated && (serverUrl?.isNotEmpty ?? false) && (userId?.isNotEmpty ?? false));
    print(state);
  }

  Future<bool> login(UserCredentials credentials) async {
    state = const AsyncLoading<bool>();
    _api = JellyfinApi(_client, baseUrl: credentials.serverUrl);
    try {
      final response = await _api.signIn(credentials.toJson());
      final token = _getAuthHeaderFromResponse(response);
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userIdKey, value: response.data.id);
      await _storage.write(key: _serverUrlKey, value: credentials.serverUrl);

      _ref.read(baseUrlProvider.notifier).state = credentials.serverUrl;
      _ref.read(currentUserProvider.notifier).state = response.data.id;
      final tokenValidated = _validateAuthToken(token);
      if (tokenValidated) _setAuthHeader(token!);
      state = AsyncValue<bool?>.data(tokenValidated);
    } on DioException catch (e) {
      state = AsyncError(e.error!, e.stackTrace);
    }
    return state.value ?? false;
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
    _removeAuthHeader();
    state = const AsyncValue<bool?>.data(false);
  }

  String? _getAuthHeaderFromResponse(HttpResponse<dynamic> response) => response.response.data['AccessToken'] as String;

  bool _validateAuthToken(String? token) {
    // if (token == null) return false;

    // final tokenPayload = JwtDecoder.decode(token);
    // final exp = tokenPayload['exp'] as int?;

    // if (exp == null) return true;

    // final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    // final now = DateTime.now();

    // return expirationTime.isAfter(now);
    return token != null;
  }

  void _setServerUrl(String url) {
    _api = JellyfinApi(_client, baseUrl: url);
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
