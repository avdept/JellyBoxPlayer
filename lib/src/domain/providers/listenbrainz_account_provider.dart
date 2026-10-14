import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_client.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/keychain_access.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';

enum ListenBrainzStatus {
  loading,
  disconnected,
  connecting,
  connected,
  tokenRejected,
}

@immutable
class ListenBrainzAccount {
  const ListenBrainzAccount({
    required this.status,
    this.userName,
    this.token,
    this.error,
    this.apiUrl = ListenBrainzClient.defaultApiUrl,
  });

  final ListenBrainzStatus status;
  final String? userName;
  final String? token;
  final String? error;
  final String apiUrl;

  bool get isConnected => status == ListenBrainzStatus.connected;
}

class ListenBrainzAccountNotifier extends StateNotifier<ListenBrainzAccount> {
  ListenBrainzAccountNotifier(
    Ref ref, {
    ListenBrainzClient? client,
    bool restore = true,
  }) : _ref = ref,
       _client = client ?? ListenBrainzClient(),
       super(const ListenBrainzAccount(status: ListenBrainzStatus.loading)) {
    if (restore) unawaited(_restore());
  }

  static const tokenKey = 'listenbrainz_token';
  static const _disconnected = ListenBrainzAccount(
    status: ListenBrainzStatus.disconnected,
  );

  final Ref _ref;
  final ListenBrainzClient _client;
  var _attempt = 0;

  Future<void> _restore() async {
    final attempt = _attempt;
    try {
      await _ref.read(sharedPreferencesProvider.future);
      final settings = _ref.read(appSettingsProvider.notifier);
      final userName = settings.valueOf(AppSetting.listenBrainzUser);
      final apiUrl = settings.valueOf(AppSetting.listenBrainzApiUrl);
      final token = await KeychainAccess(
        _ref.read(secureStorageProvider),
      ).readSessionKey(tokenKey);
      if (!mounted || attempt != _attempt) return;
      if (token != null && token.isNotEmpty && userName.isNotEmpty) {
        state = ListenBrainzAccount(
          status: ListenBrainzStatus.connected,
          userName: userName,
          token: token,
          apiUrl: apiUrl.isEmpty ? ListenBrainzClient.defaultApiUrl : apiUrl,
        );
        return;
      }
    } on Object catch (error) {
      debugPrint('[ListenBrainz] restoring the account failed: $error');
    }
    if (mounted && attempt == _attempt) state = _disconnected;
  }

  Future<bool> connect(String token, {String? apiUrl}) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      _fail('Enter your ListenBrainz user token');
      return false;
    }
    final endpoint = ListenBrainzClient.normalizeApiUrl(apiUrl ?? '');
    if (endpoint == null) {
      _fail('Enter a valid ListenBrainz API URL');
      return false;
    }

    final attempt = ++_attempt;
    state = ListenBrainzAccount(
      status: ListenBrainzStatus.connecting,
      apiUrl: endpoint,
    );
    try {
      final userName = await _client.validateToken(trimmed, apiUrl: endpoint);
      if (!mounted || attempt != _attempt) return false;
      await _ref
          .read(secureStorageProvider)
          .write(key: tokenKey, value: trimmed);
      if (!mounted || attempt != _attempt) return false;
      _ref.read(appSettingsProvider.notifier)
        ..setValue(AppSetting.listenBrainzUser, userName)
        ..setValue(
          AppSetting.listenBrainzApiUrl,
          endpoint == ListenBrainzClient.defaultApiUrl ? '' : endpoint,
        );
      state = ListenBrainzAccount(
        status: ListenBrainzStatus.connected,
        userName: userName,
        token: trimmed,
        apiUrl: endpoint,
      );
      return true;
    } on NotListenBrainzServerException catch (error) {
      if (attempt != _attempt) return false;
      _fail('${error.apiUrl} is not a ListenBrainz server');
      return false;
    } on ScrobbleException catch (error) {
      if (attempt != _attempt) return false;
      _fail(
        error.isUnauthorized
            ? 'ListenBrainz did not accept this token'
            : 'Could not reach ListenBrainz: ${error.message}',
      );
      return false;
    } on Object catch (error) {
      if (attempt != _attempt) return false;
      _fail('Connecting failed: $error');
      return false;
    }
  }

  Future<void> disconnect() async {
    _attempt++;
    state = _disconnected;
    _ref.read(appSettingsProvider.notifier)
      ..setValue(AppSetting.listenBrainzUser, '')
      ..setValue(AppSetting.listenBrainzApiUrl, '');
    try {
      await _ref.read(secureStorageProvider).delete(key: tokenKey);
    } on Object catch (error) {
      debugPrint('[ListenBrainz] removing the token failed: $error');
    }
  }

  void markTokenRejected() {
    if (!state.isConnected) return;
    state = ListenBrainzAccount(
      status: ListenBrainzStatus.tokenRejected,
      userName: state.userName,
      token: state.token,
      apiUrl: state.apiUrl,
      error:
          'ListenBrainz rejected the saved token. Connect again with a new one.',
    );
  }

  void _fail(String message) {
    if (!mounted) return;
    state = ListenBrainzAccount(
      status: ListenBrainzStatus.disconnected,
      error: message,
      apiUrl: state.apiUrl,
    );
  }
}

final listenBrainzAccountProvider =
    StateNotifierProvider<ListenBrainzAccountNotifier, ListenBrainzAccount>(
      ListenBrainzAccountNotifier.new,
    );
