import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/fanart/fanart_client.dart';
import 'package:jplayer/src/core/http/user_agent.dart';
import 'package:jplayer/src/core/telemetry/telemetry.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/keychain_access.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';

enum FanartStatus { loading, link, checking, ownKeys, rejected }

@immutable
class FanartAccount {
  const FanartAccount({
    required this.status,
    this.credentials = FanartCredentials.none,
    this.error,
  });

  final FanartStatus status;
  final FanartCredentials credentials;
  final String? error;

  bool get usesOwnKeys => status == FanartStatus.ownKeys;
}

class FanartAccountNotifier extends StateNotifier<FanartAccount> {
  FanartAccountNotifier(Ref ref, {FanartClient? client, bool restore = true})
    : _ref = ref,
      _client = client,
      super(const FanartAccount(status: FanartStatus.loading)) {
    if (restore) unawaited(_restore());
  }

  static const apiKeyKey = 'fanart_api_key';
  static const clientKeyKey = 'fanart_client_key';
  static const _link = FanartAccount(status: FanartStatus.link);

  final Ref _ref;
  final FanartClient? _client;

  FanartClient get _api => _client ?? _ref.read(fanartClientProvider);
  var _attempt = 0;

  Future<void> _restore() async {
    final attempt = _attempt;
    try {
      final keychain = KeychainAccess(_ref.read(secureStorageProvider));
      final apiKey = await keychain.readSessionKey(apiKeyKey);
      final clientKey = await keychain.readSessionKey(clientKeyKey);
      if (!mounted || attempt != _attempt) return;
      final credentials = FanartCredentials(
        apiKey: apiKey ?? '',
        clientKey: clientKey ?? '',
      );
      if (!credentials.isEmpty) {
        state = FanartAccount(
          status: FanartStatus.ownKeys,
          credentials: credentials,
        );
        return;
      }
    } on Object catch (error) {
      debugPrint('[fanart.tv] restoring the keys failed: $error');
    }
    if (mounted && attempt == _attempt) state = _link;
  }

  Future<bool> useKeys({String apiKey = '', String clientKey = ''}) async {
    final credentials = FanartCredentials(
      apiKey: apiKey.trim(),
      clientKey: clientKey.trim(),
    );
    if (credentials.isEmpty) {
      await useLink();
      return true;
    }

    final attempt = ++_attempt;
    state = FanartAccount(
      status: FanartStatus.checking,
      credentials: credentials,
    );
    try {
      await _api.validate(credentials);
    } on FanartException catch (error) {
      if (attempt != _attempt) return false;
      return _fail(switch (error.failure) {
        FanartFailure.badKey => 'fanart.tv rejected these keys',
        _ => 'Could not reach fanart.tv: ${error.message}',
      }, credentials: credentials);
    } on Object catch (error) {
      if (attempt != _attempt) return false;
      return _fail(
        'Could not reach fanart.tv: $error',
        credentials: credentials,
      );
    }
    if (!mounted || attempt != _attempt) return false;
    final storage = _ref.read(secureStorageProvider);
    try {
      await _store(storage, apiKeyKey, credentials.apiKey);
      await _store(storage, clientKeyKey, credentials.clientKey);
    } on Object catch (error) {
      debugPrint('[fanart.tv] could not store the keys: $error');
    }
    if (!mounted || attempt != _attempt) return false;
    state = FanartAccount(
      status: FanartStatus.ownKeys,
      credentials: credentials,
    );
    Telemetry.integrationConnected('fanart-own-keys');
    return true;
  }

  Future<void> useLink() async {
    _attempt++;
    state = _link;
    final storage = _ref.read(secureStorageProvider);
    try {
      await storage.delete(key: apiKeyKey);
      await storage.delete(key: clientKeyKey);
    } on Object catch (error) {
      debugPrint('[fanart.tv] could not remove the keys: $error');
    }
  }

  static Future<void> _store(
    FlutterSecureStorage storage,
    String key,
    String value,
  ) => value.isEmpty
      ? storage.delete(key: key)
      : storage.write(key: key, value: value);

  bool _fail(String message, {FanartCredentials? credentials}) {
    if (mounted) {
      state = FanartAccount(
        status: FanartStatus.rejected,
        credentials: credentials ?? FanartCredentials.none,
        error: message,
      );
    }
    return false;
  }
}

final fanartAccountProvider =
    StateNotifierProvider<FanartAccountNotifier, FanartAccount>(
      FanartAccountNotifier.new,
    );

final fanartClientProvider = Provider<FanartClient>(
  (ref) => FanartClient(
    userAgent: jellyboxUserAgent(),
    linkUrl: ref.watch(conductorUrlProvider),
    cache: ref.watch(catalogCacheDatabaseProvider),
  ),
);

final fanartCredentialsProvider = Provider<FanartCredentials>((ref) {
  final account = ref.watch(fanartAccountProvider);
  return account.usesOwnKeys ? account.credentials : FanartCredentials.none;
});

final fanartArtistBackgroundsProvider = Provider<bool>(
  (ref) => ref.watch(settingProvider(AppSetting.fanartArtistBackgrounds)),
);

String? fanartArtistId(LibraryItem artist) =>
    artist.externalIds[ExternalIdProvider.musicBrainzArtist];

final FutureProviderFamily<FanartArtistImages, String>
fanartArtistImagesProvider = FutureProvider.family<FanartArtistImages, String>(
  (ref, musicBrainzId) => ref
      .watch(fanartClientProvider)
      .artist(musicBrainzId, ref.watch(fanartCredentialsProvider)),
);
