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
  });

  final ListenBrainzStatus status;
  final String? userName;
  final String? token;
  final String? error;

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
      final userName = _ref
          .read(appSettingsProvider.notifier)
          .valueOf(AppSetting.listenBrainzUser);
      final token = await KeychainAccess(
        _ref.read(secureStorageProvider),
      ).readSessionKey(tokenKey);
      if (!mounted || attempt != _attempt) return;
      if (token != null && token.isNotEmpty && userName.isNotEmpty) {
        state = ListenBrainzAccount(
          status: ListenBrainzStatus.connected,
          userName: userName,
          token: token,
        );
        return;
      }
    } on Object catch (error) {
      debugPrint('[ListenBrainz] restoring the account failed: $error');
    }
    if (mounted && attempt == _attempt) state = _disconnected;
  }

  Future<bool> connect(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      _fail('Enter your ListenBrainz user token');
      return false;
    }

    final attempt = ++_attempt;
    state = const ListenBrainzAccount(status: ListenBrainzStatus.connecting);
    try {
      final userName = await _client.validateToken(trimmed);
      if (!mounted || attempt != _attempt) return false;
      await _ref
          .read(secureStorageProvider)
          .write(key: tokenKey, value: trimmed);
      if (!mounted || attempt != _attempt) return false;
      _ref
          .read(appSettingsProvider.notifier)
          .setValue(AppSetting.listenBrainzUser, userName);
      state = ListenBrainzAccount(
        status: ListenBrainzStatus.connected,
        userName: userName,
        token: trimmed,
      );
      return true;
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
    _ref
        .read(appSettingsProvider.notifier)
        .setValue(AppSetting.listenBrainzUser, '');
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
      error:
          'ListenBrainz rejected the saved token. Connect again with a new one.',
    );
  }

  void _fail(String message) {
    if (!mounted) return;
    state = ListenBrainzAccount(
      status: ListenBrainzStatus.disconnected,
      error: message,
    );
  }
}

final listenBrainzAccountProvider =
    StateNotifierProvider<ListenBrainzAccountNotifier, ListenBrainzAccount>(
      ListenBrainzAccountNotifier.new,
    );
