import 'dart:async';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show PaintingBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/network/certificate_trust.dart';
import 'package:jplayer/src/data/backend/media_server_backends.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/media_server_exception.dart';
import 'package:jplayer/src/data/backend/quick_connect.dart';
import 'package:jplayer/src/data/backend/server_auth_headers.dart';
import 'package:jplayer/src/data/backend/server_session.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:jplayer/src/data/services/server_data_cleaner.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/data/storages/account_store.dart';
import 'package:jplayer/src/data/storages/keychain_access.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/forward_cache_provider.dart';
import 'package:jplayer/src/domain/providers/libraries_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/accounts_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/current_server_type_provider.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:jplayer/src/providers/server_addresses_provider.dart';
import 'package:jplayer/src/providers/session_providers.dart';

class AuthNotifier extends AsyncNotifier<bool?> {
  AuthNotifier() {
    _noAuthNetworkInterceptor = InterceptorsWrapper(
      onError: (error, handler) {
        final failure = MediaServerException.fromDio(error);
        if (failure.isUnauthorized &&
            _hasActiveSession &&
            !_authenticating &&
            !_loggingOut &&
            !_switching &&
            _isActiveServer(error.requestOptions.uri)) {
          debugPrint(
            '[Auth] HTTP ${failure.statusCode} from '
            '${error.requestOptions.uri.host}, re-checking the session',
          );
          unawaited(_expireIfSessionInvalid());
        }
        handler.next(error);
      },
    );
  }

  late final Interceptor _noAuthNetworkInterceptor;
  late Dio _client;
  late FlutterSecureStorage _storage;
  late KeychainAccess _keychain;
  late AccountStore _accounts;

  bool _authenticating = false;
  bool _loggingOut = false;
  bool _switching = false;
  bool _recheckingSession = false;
  _QuickConnectSession? _quickConnect;

  static const serverUnreachableError =
      'Server is not accessible. Check the server URL and your connection.';
  static const invalidCredentialsError = 'Incorrect login or password';
  static const untrustedCertificateError =
      "The server's security certificate is not trusted.";
  static const quickConnectUnavailableError =
      'Quick Connect is not available on this server.';
  static const quickConnectExpiredError =
      'The Quick Connect code expired. Try again.';
  static const quickConnectCancelled = 'quick-connect-cancelled';
  static const alreadyAddedError = 'This server is already added.';

  static const _sessionValidationTimeout = Duration(seconds: 6);
  static const _quickConnectPollInterval = Duration(seconds: 3);
  static const _quickConnectTimeout = Duration(minutes: 5);

  static const _serverUrlKey = 'serverUrl';
  static const _lastServerUrlKey = 'lastServerUrl';
  static const _serverTypeKey = 'serverType';
  static const _serverIdKey = 'serverId';
  static const _userIdKey = 'userId';
  static const _authTokenKey = 'authToken';

  static const _legacyAuthTokenKey = 'x-mediabrowser-token';

  @override
  FutureOr<bool?> build() async {
    _client = ref.watch(dioProvider);
    _storage = ref.watch(secureStorageProvider);
    _keychain = KeychainAccess(_storage);
    _accounts = AccountStore(_storage);
    if (!_client.interceptors.contains(_noAuthNetworkInterceptor)) {
      _client.interceptors.add(_noAuthNetworkInterceptor);
    }
    ref.onDispose(() {
      _client.interceptors.remove(_noAuthNetworkInterceptor);
    });

    state = const AsyncLoading();

    final serverUrl = await _keychain.readSessionKey(_serverUrlKey);
    await _loadAccounts();
    return _restoreSession(serverUrl);
  }

  Future<bool> _restoreSession(String? serverUrl) async {
    ref.read(baseUrlProvider.notifier).state = serverUrl;
    if (serverUrl == null) return false;
    await _rememberServerUrl(serverUrl);
    final remoteUrl = await _storage.read(key: remoteUrlStorageKey);
    final relayUrl = await _storage.read(key: relayUrlStorageKey);
    ref.read(serverAddressesProvider.notifier).state = ServerAddresses(
      home: serverUrl,
      remote: remoteUrl,
      relay: relayUrl,
    );

    final serverType = _parseServerType(
      await _storage.read(key: _serverTypeKey),
    );
    ref.read(currentServerTypeProvider.notifier).state = serverType;

    final userId = await _storage.read(key: _userIdKey) ?? '';
    final serverId = await _resolveServerId(serverUrl);
    ref.read(currentServerIdProvider.notifier).state = serverId;
    await _pruneAbandonedDownloads();
    final token = await _migrateAuthToken();
    final (activeUrl, status) = await _validateFirst(
      [serverUrl, ?remoteUrl, ?relayUrl],
      serverType,
      userId: userId,
      token: token,
    );
    ref.read(baseUrlProvider.notifier).state = activeUrl;
    final sessionUsable = status != SessionStatus.invalid;

    if (sessionUsable) {
      ref.read(currentUserProvider.notifier).state = User(
        userId: userId,
        token: token,
      );
      _setAuthHeader(serverType, token);
      if (status == SessionStatus.valid) await _adoptLegacyDownloads();
    }
    await _syncActiveAccount(needsReauth: !sessionUsable);
    if (status == SessionStatus.valid && serverId != null) {
      unawaited(_backfillIdentity(serverId, activeUrl));
    }

    return sessionUsable && serverUrl.isNotEmpty && userId.isNotEmpty;
  }

  Future<String?> login(
    UserCredentials credentials, {
    ServerType? serverType,
  }) async {
    if (_authenticating) return null;
    final serverUrl = normalizeServerUrl(credentials.serverUrl);
    ref.read(certificateTrustProvider).clearRejections();
    _authenticating = true;
    try {
      final resolved = serverType ?? await _detectServerType(serverUrl);
      return await _signIn(resolved, serverUrl, credentials);
    } finally {
      _authenticating = false;
    }
  }

  Future<ServerType> _detectServerType(String serverUrl) async {
    final detected = await ref
        .read(serverProbeServiceProvider)
        .detectType(serverUrl);
    return detected ?? ServerType.jellyfin;
  }

  Future<String?> _signIn(
    ServerType serverType,
    String serverUrl,
    UserCredentials credentials,
  ) async {
    try {
      final session = await authenticatorFor(
        serverType,
        dio: _signInClient(serverType),
      ).signIn(credentials, serverUrl: serverUrl);
      return await _completeSignIn(
        serverType,
        serverUrl,
        session,
        userName: credentials.username,
      );
    } on DioException catch (e) {
      return _loginErrorMessage(MediaServerException.fromDio(e), serverUrl);
    } on MediaServerException catch (e) {
      return _loginErrorMessage(e, serverUrl);
    }
  }

  bool get _hasActiveSession => state.valueOrNull ?? false;

  bool _isActiveServer(Uri uri) {
    final addresses = ref.read(serverAddressesProvider);
    if (addresses == null) return false;
    return addresses.candidates.any((url) {
      final candidate = Uri.tryParse(url);
      return candidate != null &&
          candidate.scheme == uri.scheme &&
          candidate.host == uri.host &&
          candidate.port == uri.port;
    });
  }

  Dio _signInClient(ServerType serverType) {
    if (!_hasActiveSession) {
      _setAuthHeader(serverType);
      return _client;
    }
    return _detachedClient(_authHeadersOf(serverType).build());
  }

  bool isAdded(String? serverId) {
    final account = _accountFor(serverId);
    return account != null && !account.needsReauth;
  }

  Future<String?> _completeSignIn(
    ServerType serverType,
    String serverUrl,
    ServerSession session, {
    String? userName,
  }) async {
    if (_hasActiveSession && isAdded(session.serverId)) {
      return alreadyAddedError;
    }
    final existing = _accountFor(session.serverId);
    final identity = await _identify(serverUrl);
    final account = ServerAccount(
      serverId: session.serverId,
      serverType: serverType,
      url: serverUrl,
      userId: session.userId,
      token: session.token,
      userName: userName ?? existing?.userName,
      serverName: identity?.name ?? existing?.serverName,
      productName: identity?.productName ?? existing?.productName,
      remoteUrl: existing?.remoteUrl,
      relayUrl: existing?.relayUrl,
      libraryId: existing?.libraryId,
      libraryPath: existing?.libraryPath,
      libraryName: existing?.libraryName,
      libraries: existing?.libraries ?? const [],
    );
    await _upsertAccount(account);
    if (_hasActiveSession) {
      await switchTo(account.serverId);
    } else {
      await _establishSession(account);
    }
    return state.error?.toString();
  }

  Future<void> _establishSession(ServerAccount account) async {
    final serverType = account.serverType;
    final serverUrl = account.url;
    final token = account.token;
    final userId = account.userId;
    await _writeActiveKeys(account);

    ref.read(currentServerIdProvider.notifier).state = account.serverId;
    await _pruneAbandonedDownloads();
    ref.read(serverAddressesProvider.notifier).state = ServerAddresses(
      home: serverUrl,
      remote: account.remoteUrl,
      relay: account.relayUrl,
    );
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
    final status = await _validateSession(client, token, serverType);
    final sessionUsable = status != SessionStatus.invalid;
    if (sessionUsable) {
      _setAuthHeader(serverType, token);
      await _adoptLegacyDownloads();
    }
    state = AsyncData(sessionUsable);
  }

  Future<QuickConnectRequest?> beginQuickConnect(
    String serverUrl, {
    ServerType? serverType,
  }) async {
    final url = normalizeServerUrl(serverUrl);
    ref.read(certificateTrustProvider).clearRejections();
    _authenticating = true;
    try {
      final resolved = serverType ?? await _detectServerType(url);
      final authenticator = quickConnectFor(
        resolved,
        dio: _signInClient(resolved),
      );
      if (authenticator == null) {
        _authenticating = false;
        if (!_hasActiveSession) _removeAuthHeader();
        return null;
      }
      final request = await authenticator.initiate(serverUrl: url);
      _quickConnect = _QuickConnectSession(
        authenticator: authenticator,
        serverType: resolved,
        serverUrl: url,
        request: request,
      );
      return request;
    } on Object {
      _authenticating = false;
      if (!_hasActiveSession) _removeAuthHeader();
      return null;
    }
  }

  Future<String?> awaitQuickConnect() async {
    final session = _quickConnect!;
    final deadline = DateTime.now().add(_quickConnectTimeout);
    try {
      while (DateTime.now().isBefore(deadline)) {
        if (session.cancelled) return quickConnectCancelled;
        final failure = await _pollQuickConnect(session);
        if (session.cancelled) return quickConnectCancelled;
        if (session.authorized) return null;
        if (failure != null) return failure;
        await Future<void>.delayed(_quickConnectPollInterval);
      }
      return quickConnectExpiredError;
    } finally {
      if (identical(_quickConnect, session)) _quickConnect = null;
      _authenticating = false;
      if (!session.authorized && !_hasActiveSession) _removeAuthHeader();
    }
  }

  Future<String?> _pollQuickConnect(_QuickConnectSession session) async {
    try {
      final result = await session.authenticator.poll(
        session.request,
        serverUrl: session.serverUrl,
      );
      if (result == null) return null;
      final failure = await _completeSignIn(
        session.serverType,
        session.serverUrl,
        result,
      );
      if (failure != null) return failure;
      session.authorized = true;
      return null;
    } on DioException catch (e) {
      return _quickConnectErrorMessage(
        MediaServerException.fromDio(e),
        session.serverUrl,
      );
    } on MediaServerException catch (e) {
      return _quickConnectErrorMessage(e, session.serverUrl);
    }
  }

  void cancelQuickConnect() => _quickConnect?.cancelled = true;

  String _quickConnectErrorMessage(MediaServerException e, String serverUrl) {
    if (e.isNotFound || e.isUnauthorized) return quickConnectExpiredError;
    return _loginErrorMessage(e, serverUrl);
  }

  String _loginErrorMessage(MediaServerException e, String serverUrl) {
    if (_rejectedCertificateFor(serverUrl) != null) {
      return untrustedCertificateError;
    }
    return e.isUnauthorized ? invalidCredentialsError : serverUnreachableError;
  }

  ServerCertificate? _rejectedCertificateFor(String serverUrl) {
    final host = Uri.tryParse(serverUrl)?.host;
    if (host == null || host.isEmpty) return null;
    return ref.read(certificateTrustProvider).rejectedFor(host);
  }

  Future<void> logout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    state = const AsyncLoading();
    try {
      await _stopPlayback();
      await _purgeQueueCache();
      PaintingBinding.instance.imageCache.clear();
      final lastServerUrl = await _storage.read(key: _lastServerUrlKey);
      final activeId = ref.read(currentServerIdProvider);
      final others = [
        for (final account in ref.read(accountsProvider))
          if (account.serverId != activeId) account,
      ];
      await Future.wait([
        _signOutQuietly(),
        for (final account in others) _signOutAccount(account),
      ]);
      await Future.wait([
        ref.read(sharedPreferencesProvider).requireValue.clear(),
        _storage.deleteAll(),
        ref.read(certificateTrustProvider).clear(),
        ArtworkCache.instance.emptyCache(),
      ]);
      if (lastServerUrl != null) await _rememberServerUrl(lastServerUrl);
    } finally {
      ref.read(accountsProvider.notifier).state = const [];
      _clearSession();
      _removeAuthHeader();
      state = const AsyncData(false);
      _loggingOut = false;
    }
  }

  Future<void> updateHomeUrl(String url) async {
    final home = normalizeServerUrl(url);
    final addresses = ref.read(serverAddressesProvider);
    if (addresses == null || addresses.home == home) return;
    await _storage.write(key: _serverUrlKey, value: home);
    await _rememberServerUrl(home);
    if (ref.read(baseUrlProvider) == addresses.home) {
      ref.read(baseUrlProvider.notifier).state = home;
    }
    ref.read(serverAddressesProvider.notifier).state = addresses.copyWith(
      home: home,
    );
    await _syncActiveAccount();
  }

  Future<SessionStatus> sessionStatusAt(String url) async {
    final user = ref.read(currentUserProvider);
    final serverType = ref.read(currentServerTypeProvider);
    if (user == null || serverType == null) return SessionStatus.unreachable;
    return _sessionStatus(
      _clientFor(
        serverType,
        serverUrl: url,
        userId: user.userId,
        token: user.token,
      ),
    );
  }

  Future<void> switchTo(String serverId, {LibraryItem? library}) async {
    final account = _accountFor(serverId);
    if (account == null || _switching || _loggingOut) return;
    final target = library == null
        ? account
        : account.copyWith(
            libraryId: () => library.id,
            libraryPath: () => library.path,
            libraryName: () => library.name,
          );
    if (serverId == ref.read(currentServerIdProvider) && _hasActiveSession) {
      return;
    }
    _switching = true;
    state = const AsyncLoading();
    try {
      await _syncActiveAccount();
      await _tearDownActive();
      await _writeActiveKeys(target);
      state = await _restoreInto(target);
    } finally {
      _switching = false;
    }
    _restoreQueue();
  }

  void _restoreQueue() {
    if (!_hasActiveSession) return;
    try {
      unawaited(
        ref
            .read(playbackProvider.notifier)
            .tryRestore()
            .catchError((_) => false),
      );
    } on Object {
      return;
    }
  }

  Future<AsyncValue<bool>> _restoreInto(ServerAccount account) async {
    final restored = await AsyncValue.guard(
      () => _restoreSession(account.url),
    );
    if (restored.valueOrNull == true && account.libraryId == null) {
      await _selectFirstLibrary(account.serverId);
    }
    return restored;
  }

  Future<void> _selectFirstLibrary(String serverId) async {
    try {
      final page = await ref
          .read(mediaServerClientProvider)
          .getLibraries()
          .timeout(_sessionValidationTimeout);
      final first = musicLibraries(page.items).firstOrNull;
      final account = _accountFor(serverId);
      if (first == null || account == null) return;
      final selected = account.copyWith(
        libraryId: () => first.id,
        libraryPath: () => first.path,
        libraryName: () => first.name,
      );
      await _applyLibrary(selected);
      await _upsertAccount(selected);
    } on Object {
      return;
    }
  }

  Future<void> removeAccount(String serverId) async {
    final account = _accountFor(serverId);
    if (account == null || _switching || _loggingOut) return;
    final remaining = [
      for (final other in ref.read(accountsProvider))
        if (other.serverId != serverId) other,
    ];
    if (await _storage.read(key: _serverIdKey) != serverId) {
      await _signOutAccount(account);
      await _deleteServerData(serverId);
      await _saveAccounts(remaining);
      return;
    }

    _switching = true;
    state = const AsyncLoading();
    try {
      await _signOutQuietly();
      await _cancelDownloads();
      await _tearDownActive();
      await _deleteServerData(serverId);
      await _deleteActiveKeys();
      await _saveAccounts(remaining);
      final next =
          remaining.firstWhereOrNull((other) => !other.needsReauth) ??
          remaining.firstOrNull;
      if (next == null) {
        await _applyLibrary(null);
        state = const AsyncData(false);
        return;
      }
      await _writeActiveKeys(next);
      state = await _restoreInto(next);
    } finally {
      _switching = false;
    }
    _restoreQueue();
  }

  Future<void> _expireIfSessionInvalid() async {
    if (_recheckingSession) return;
    final user = ref.read(currentUserProvider);
    final serverType = ref.read(currentServerTypeProvider);
    final addresses = ref.read(serverAddressesProvider);
    if (user == null || serverType == null || addresses == null) {
      return _expireActive();
    }
    _recheckingSession = true;
    try {
      final statuses = await Future.wait([
        for (final url in addresses.candidates)
          _sessionStatus(
            _clientFor(
              serverType,
              serverUrl: url,
              userId: user.userId,
              token: user.token,
            ),
          ),
      ]);
      if (statuses.contains(SessionStatus.valid)) {
        debugPrint('[Auth] the session is still valid, staying signed in');
      } else if (statuses.contains(SessionStatus.invalid)) {
        debugPrint('[Auth] the server rejected the session, signing out');
        await _expireActive();
      }
    } finally {
      _recheckingSession = false;
    }
  }

  Future<void> _expireActive() async {
    if (_loggingOut || _switching) return;
    _loggingOut = true;
    state = const AsyncLoading();
    try {
      await _syncActiveAccount(needsReauth: true);
      await _tearDownActive();
      await _deleteActiveKeys();
      await _applyLibrary(null);
    } finally {
      state = const AsyncData(false);
      _loggingOut = false;
    }
  }

  Future<ServerIdentity?> _identify(String serverUrl) async {
    try {
      return await ref
          .read(serverProbeServiceProvider)
          .probe(serverUrl)
          .timeout(_sessionValidationTimeout);
    } on Object {
      return null;
    }
  }

  Future<void> _backfillIdentity(String serverId, String serverUrl) async {
    final account = _accountFor(serverId);
    if (account == null || account.productName != null) return;
    final identity = await _identify(serverUrl);
    if (identity == null) return;
    final current = _accountFor(serverId);
    if (current == null) return;
    await _upsertAccount(
      current.copyWith(
        serverName: () => identity.name ?? current.serverName,
        productName: () => identity.productName,
      ),
    );
  }

  Future<void> rememberLibraries(
    String serverId,
    List<SavedLibrary> libraries,
  ) async {
    final account = _accountFor(serverId);
    if (account == null) return;
    await _upsertAccount(account.copyWith(libraries: libraries));
  }

  Future<void> _deleteServerData(String serverId) async {
    try {
      await ref.read(serverDataCleanerProvider(serverId)).deleteAll();
    } on Object catch (e) {
      log('Deleting data of $serverId failed: $e', name: 'Auth');
    }
  }

  Future<void> _cancelDownloads() async {
    try {
      await ref.read(downloadServiceProvider).cancelAll();
    } on Object {
      return;
    }
  }

  Future<void> _tearDownActive() async {
    await _stopPlayback();
    await _purgeQueueCache();
    PaintingBinding.instance.imageCache.clear();
    _clearSession();
    _removeAuthHeader();
  }

  ServerAccount? _accountFor(String? serverId) => serverId == null
      ? null
      : ref
            .read(accountsProvider)
            .firstWhereOrNull((account) => account.serverId == serverId);

  Future<void> _loadAccounts() async {
    ref.read(accountsProvider.notifier).state =
        await _accounts.load() ?? const [];
  }

  Future<void> _saveAccounts(List<ServerAccount> accounts) async {
    ref.read(accountsProvider.notifier).state = List.unmodifiable(accounts);
    await _accounts.save(accounts);
  }

  Future<void> _upsertAccount(ServerAccount account) async {
    final accounts = ref.read(accountsProvider);
    final index = accounts.indexWhere(
      (existing) => existing.serverId == account.serverId,
    );
    if (index >= 0 && accounts[index] == account) return;
    await _saveAccounts([
      if (index < 0) ...[...accounts, account],
      if (index >= 0)
        for (final (i, existing) in accounts.indexed)
          i == index ? account : existing,
    ]);
  }

  Future<void> _syncActiveAccount({bool? needsReauth}) async {
    final serverId = await _storage.read(key: _serverIdKey);
    final serverUrl = await _storage.read(key: _serverUrlKey);
    final userId = await _storage.read(key: _userIdKey);
    final token = await _storage.read(key: _authTokenKey);
    if (serverId == null ||
        serverId.isEmpty ||
        serverUrl == null ||
        userId == null ||
        token == null) {
      return;
    }
    final existing = _accountFor(serverId);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await _upsertAccount(
      ServerAccount(
        serverId: serverId,
        serverType: _parseServerType(await _storage.read(key: _serverTypeKey)),
        url: serverUrl,
        userId: userId,
        token: token,
        userName: existing?.userName,
        serverName: existing?.serverName,
        productName: existing?.productName,
        remoteUrl: await _storage.read(key: remoteUrlStorageKey),
        relayUrl: await _storage.read(key: relayUrlStorageKey),
        libraryId: prefs.getString(CurrentLibraryNotifier.libraryIdStorageKey),
        libraryPath: prefs.getString(
          CurrentLibraryNotifier.libraryPathStorageKey,
        ),
        libraryName: prefs.getString(
          CurrentLibraryNotifier.libraryNameStorageKey,
        ),
        libraries: existing?.libraries ?? const [],
        needsReauth: needsReauth ?? existing?.needsReauth ?? false,
      ),
    );
  }

  Future<void> _writeActiveKeys(ServerAccount account) async {
    await _storage.write(key: _authTokenKey, value: account.token);
    await _storage.write(key: _userIdKey, value: account.userId);
    await _storage.write(key: _serverUrlKey, value: account.url);
    await _storage.write(key: _serverIdKey, value: account.serverId);
    await _storage.write(key: _serverTypeKey, value: account.serverType.name);
    await _writeOrDelete(remoteUrlStorageKey, account.remoteUrl);
    await _writeOrDelete(relayUrlStorageKey, account.relayUrl);
    await _rememberServerUrl(account.url);
    await _applyLibrary(account);
  }

  Future<void> _deleteActiveKeys() async {
    for (final key in const [
      _authTokenKey,
      _legacyAuthTokenKey,
      _userIdKey,
      _serverUrlKey,
      _serverIdKey,
      _serverTypeKey,
      remoteUrlStorageKey,
      relayUrlStorageKey,
    ]) {
      await _storage.delete(key: key);
    }
  }

  Future<void> _writeOrDelete(String key, String? value) => value == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: value);

  Future<void> _applyLibrary(ServerAccount? account) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final values = {
      CurrentLibraryNotifier.libraryIdStorageKey: account?.libraryId,
      CurrentLibraryNotifier.libraryPathStorageKey: account?.libraryPath,
      CurrentLibraryNotifier.libraryNameStorageKey: account?.libraryName,
    };
    for (final MapEntry(:key, :value) in values.entries) {
      if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    }
    ref.invalidate(currentLibraryProvider);
  }

  Dio _detachedClient(Map<String, String> headers) => Dio(
    BaseOptions(
      connectTimeout: _client.options.connectTimeout,
      contentType: _client.options.contentType,
      headers: headers,
    ),
  )..httpClientAdapter = _client.httpClientAdapter;

  Future<void> _signOutAccount(ServerAccount account) async {
    try {
      final dio = _detachedClient(
        _authHeadersOf(account.serverType).build(token: account.token),
      );
      await clientFor(
        account.serverType,
        dio: dio,
        baseUrl: account.url,
        userId: account.userId,
        token: account.token,
        deviceId: deviceId,
      ).signOut().timeout(_sessionValidationTimeout);
    } on Object {
      return;
    }
  }

  Future<void> _rememberServerUrl(String serverUrl) async {
    await _storage.write(key: _lastServerUrlKey, value: serverUrl);
    ref.invalidate(lastServerUrlProvider);
  }

  Future<void> _stopPlayback() async {
    if (!ref.exists(playbackProvider)) return;
    try {
      await ref.read(playbackProvider.notifier).clear();
    } on Object {
      return;
    }
  }

  Future<void> _purgeQueueCache() async {
    try {
      if (ref.exists(forwardCacheProvider)) {
        await ref.read(forwardCacheProvider.notifier).cancelPending();
      }
      await ref.read(queueCacheServiceProvider).purge();
    } on Object {
      return;
    }
  }

  Future<String?> _resolveServerId(String serverUrl) async {
    final stored = await _storage.read(key: _serverIdKey);
    if (stored != null && stored.isNotEmpty) return stored;

    // TODO: Remove in 2.5.0, tis is one time thing to adopt dowmloads without serverId

    final identity = await ref
        .read(serverProbeServiceProvider)
        .probe(serverUrl);
    if (identity == null) return null;
    final serverId = identity.serverId ?? identity.serverUrl;
    if (serverId.isEmpty) return null;

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

  Future<void> _pruneAbandonedDownloads() async {
    try {
      final pruned = await ref
          .read(downloadDatabaseProvider)
          .pruneAbandonedSongs();
      if (pruned > 0) debugPrint('[Downloads] pruned $pruned abandoned songs');
    } on Object {
      return;
    }
  }

  void _clearSession() {
    ref.read(currentUserProvider.notifier).state = null;
    ref.read(baseUrlProvider.notifier).state = null;
    ref.read(serverAddressesProvider.notifier).state = null;
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
  }) => clientFor(
    serverType,
    dio: _client,
    baseUrl: serverUrl,
    userId: userId,
    token: token,
    deviceId: deviceId,
  );

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

  Future<SessionStatus> _validateSession(
    MediaServerClient client,
    String? token,
    ServerType serverType,
  ) async {
    if (token == null || token.isEmpty) return SessionStatus.invalid;
    try {
      _setAuthHeader(serverType, token);
      return await _sessionStatus(client);
    } finally {
      _removeAuthHeader();
    }
  }

  Future<(String, SessionStatus)> _validateFirst(
    List<String> urls,
    ServerType serverType, {
    required String userId,
    required String token,
  }) async {
    if (token.isEmpty) return (urls.first, SessionStatus.invalid);
    _setAuthHeader(serverType, token);
    try {
      final answered = Completer<(String, SessionStatus)>();
      var left = urls.length;
      (String, SessionStatus)? rejection;
      for (final url in urls) {
        final client = _clientFor(
          serverType,
          serverUrl: url,
          userId: userId,
          token: token,
        );
        unawaited(
          _sessionStatus(client).then((status) {
            left--;
            if (answered.isCompleted) return;
            if (status == SessionStatus.valid) {
              answered.complete((url, status));
              return;
            }
            if (status == SessionStatus.invalid) rejection ??= (url, status);
            if (left == 0) {
              answered.complete(
                rejection ?? (urls.first, SessionStatus.unreachable),
              );
            }
          }),
        );
      }
      return await answered.future;
    } finally {
      _removeAuthHeader();
    }
  }

  Future<SessionStatus> _sessionStatus(MediaServerClient client) async {
    try {
      return await client.validateSession().timeout(
        _sessionValidationTimeout,
        onTimeout: () => SessionStatus.unreachable,
      );
    } on Object catch (e) {
      log('Session validation failed: $e', name: 'Auth');
      return SessionStatus.unreachable;
    }
  }

  void _setAuthHeader(ServerType serverType, [String? token]) {
    _removeAuthHeader();
    _client.options.headers.addAll(
      _authHeadersOf(serverType).build(token: token),
    );

    if (kDebugMode) _notifyDeveloper();
  }

  void _removeAuthHeader() {
    for (final serverType in ServerType.values) {
      _authHeadersOf(serverType).managedKeys.forEach(
        _client.options.headers.remove,
      );
    }

    if (kDebugMode) _notifyDeveloper();
  }

  ServerAuthHeaders _authHeadersOf(ServerType serverType) => authHeadersFor(
    serverType,
    deviceId: deviceId,
    deviceName: getCurrentPlatformName(),
    version: appInfo.version,
  );

  void _notifyDeveloper() => log(
    {
      for (final serverType in ServerType.values)
        for (final key in _authHeadersOf(serverType).managedKeys)
          if (_client.options.headers.containsKey(key))
            key: _client.options.headers[key],
    }.toString(),
    name: 'Auth',
  );
}

class _QuickConnectSession {
  _QuickConnectSession({
    required this.authenticator,
    required this.serverType,
    required this.serverUrl,
    required this.request,
  });

  final QuickConnectAuthenticator authenticator;
  final ServerType serverType;
  final String serverUrl;
  final QuickConnectRequest request;

  bool cancelled = false;
  bool authorized = false;
}

final authProvider = AsyncNotifierProvider<AuthNotifier, bool?>(
  AuthNotifier.new,
);

final lastServerUrlProvider = FutureProvider<String?>((ref) async {
  try {
    return await ref
        .read(secureStorageProvider)
        .read(key: AuthNotifier._lastServerUrlKey);
  } on Object {
    return null;
  }
});
