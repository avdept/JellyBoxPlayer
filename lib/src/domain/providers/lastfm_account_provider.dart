import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/lastfm/lastfm_client.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/keychain_access.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';

enum LastFmStatus {
  loading,
  disconnected,
  authorizing,
  connecting,
  connected,
  sessionRejected,
}

@immutable
class LastFmAccount {
  const LastFmAccount({
    required this.status,
    this.credentials,
    this.userName,
    this.sessionKey,
    this.token,
    this.error,
  });

  final LastFmStatus status;
  final LastFmCredentials? credentials;
  final String? userName;
  final String? sessionKey;
  final String? token;
  final String? error;

  bool get isConnected => status == LastFmStatus.connected;

  bool get isAuthorizing => status == LastFmStatus.authorizing;
}

class LastFmAccountNotifier extends StateNotifier<LastFmAccount> {
  LastFmAccountNotifier(Ref ref, {LastFmClient? client, bool restore = true})
    : _ref = ref,
      _client = client ?? LastFmClient(),
      super(const LastFmAccount(status: LastFmStatus.loading)) {
    if (restore) unawaited(_restore());
  }

  static const apiKeyKey = 'lastfm_api_key';
  static const apiSecretKey = 'lastfm_api_secret';
  static const sessionKeyKey = 'lastfm_session_key';
  static const _disconnected = LastFmAccount(status: LastFmStatus.disconnected);

  final Ref _ref;
  final LastFmClient _client;
  var _attempt = 0;

  Future<void> _restore() async {
    final attempt = _attempt;
    try {
      await _ref.read(sharedPreferencesProvider.future);
      final userName = _ref
          .read(appSettingsProvider.notifier)
          .valueOf(AppSetting.lastFmUser);
      final keychain = KeychainAccess(_ref.read(secureStorageProvider));
      final apiKey = await keychain.readSessionKey(apiKeyKey);
      final apiSecret = await keychain.readSessionKey(apiSecretKey);
      final sessionKey = await keychain.readSessionKey(sessionKeyKey);
      if (!mounted || attempt != _attempt) return;
      if (apiKey != null &&
          apiKey.isNotEmpty &&
          apiSecret != null &&
          apiSecret.isNotEmpty &&
          sessionKey != null &&
          sessionKey.isNotEmpty &&
          userName.isNotEmpty) {
        state = LastFmAccount(
          status: LastFmStatus.connected,
          credentials: LastFmCredentials(apiKey: apiKey, apiSecret: apiSecret),
          userName: userName,
          sessionKey: sessionKey,
        );
        return;
      }
    } on Object catch (error) {
      debugPrint('[Last.fm] restoring the account failed: $error');
    }
    if (mounted && attempt == _attempt) state = _disconnected;
  }

  Future<Uri?> beginAuthorization({
    required String apiKey,
    required String apiSecret,
  }) async {
    final credentials = LastFmCredentials(
      apiKey: apiKey.trim(),
      apiSecret: apiSecret.trim(),
    );
    if (credentials.apiKey.isEmpty || credentials.apiSecret.isEmpty) {
      _fail('Enter your Last.fm API key and shared secret');
      return null;
    }
    final attempt = ++_attempt;
    state = LastFmAccount(
      status: LastFmStatus.connecting,
      credentials: credentials,
    );
    try {
      final token = await _client.getToken(credentials);
      if (!mounted || attempt != _attempt) return null;
      state = LastFmAccount(
        status: LastFmStatus.authorizing,
        credentials: credentials,
        token: token,
      );
      return LastFmClient.authorizationUrl(credentials, token);
    } on LastFmException catch (error) {
      if (attempt != _attempt) return null;
      _fail(
        error.badCredentials
            ? 'Last.fm did not accept this API key and secret'
            : 'Last.fm refused the request: ${error.message}',
        credentials: credentials,
      );
      return null;
    } on ScrobbleException catch (error) {
      if (attempt != _attempt) return null;
      _fail(
        'Could not reach Last.fm: ${error.message}',
        credentials: credentials,
      );
      return null;
    } on Object catch (error) {
      if (attempt != _attempt) return null;
      _fail('Connecting failed: $error', credentials: credentials);
      return null;
    }
  }

  Future<bool> completeAuthorization() async {
    final token = state.token;
    final credentials = state.credentials;
    if (!state.isAuthorizing || token == null || credentials == null) {
      _fail('Open Last.fm first to allow access', credentials: credentials);
      return false;
    }
    final attempt = ++_attempt;
    state = LastFmAccount(
      status: LastFmStatus.connecting,
      credentials: credentials,
      token: token,
    );
    try {
      final session = await _client.getSession(credentials, token);
      if (!mounted || attempt != _attempt) return false;
      final storage = _ref.read(secureStorageProvider);
      await storage.write(key: apiKeyKey, value: credentials.apiKey);
      await storage.write(key: apiSecretKey, value: credentials.apiSecret);
      await storage.write(key: sessionKeyKey, value: session.key);
      if (!mounted || attempt != _attempt) return false;
      _ref
          .read(appSettingsProvider.notifier)
          .setValue(AppSetting.lastFmUser, session.userName);
      state = LastFmAccount(
        status: LastFmStatus.connected,
        credentials: credentials,
        userName: session.userName,
        sessionKey: session.key,
      );
      return true;
    } on LastFmException catch (error) {
      if (attempt != _attempt) return false;
      if (error.tokenNotAuthorized) {
        state = LastFmAccount(
          status: LastFmStatus.authorizing,
          credentials: credentials,
          token: token,
          error:
              'Last.fm has not allowed access yet. Finish in your browser, then press Done again.',
        );
        return false;
      }
      _fail(
        error.isUnauthorized
            ? 'The Last.fm authorization expired. Start again.'
            : 'Last.fm refused the connection: ${error.message}',
        credentials: credentials,
      );
      return false;
    } on ScrobbleException catch (error) {
      if (attempt != _attempt) return false;
      state = LastFmAccount(
        status: LastFmStatus.authorizing,
        credentials: credentials,
        token: token,
        error: 'Could not reach Last.fm: ${error.message}',
      );
      return false;
    } on Object catch (error) {
      if (attempt != _attempt) return false;
      _fail('Connecting failed: $error', credentials: credentials);
      return false;
    }
  }

  Future<void> disconnect() async {
    _attempt++;
    state = _disconnected;
    _ref.read(appSettingsProvider.notifier).setValue(AppSetting.lastFmUser, '');
    final storage = _ref.read(secureStorageProvider);
    for (final key in const [apiKeyKey, apiSecretKey, sessionKeyKey]) {
      try {
        await storage.delete(key: key);
      } on Object catch (error) {
        debugPrint('[Last.fm] removing $key failed: $error');
      }
    }
  }

  void markSessionRejected() {
    if (!state.isConnected) return;
    state = LastFmAccount(
      status: LastFmStatus.sessionRejected,
      credentials: state.credentials,
      userName: state.userName,
      sessionKey: state.sessionKey,
      error: 'Last.fm rejected the saved session. Connect again.',
    );
  }

  void _fail(String message, {LastFmCredentials? credentials}) {
    if (!mounted) return;
    state = LastFmAccount(
      status: LastFmStatus.disconnected,
      credentials: credentials,
      error: message,
    );
  }
}

final lastFmAccountProvider =
    StateNotifierProvider<LastFmAccountNotifier, LastFmAccount>(
      LastFmAccountNotifier.new,
    );
