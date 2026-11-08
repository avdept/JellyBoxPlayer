import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/lastfm/lastfm_client.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/lastfm_account_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider_container.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeClient extends LastFmClient {
  int tokens = 0;
  final authorized = <String>{};
  final expired = <String>{};
  final credentialsSeen = <LastFmCredentials>[];
  ScrobbleException? failWith;
  Future<LastFmSession> Function(String token)? session;

  @override
  Future<String> getToken(LastFmCredentials credentials) async {
    credentialsSeen.add(credentials);
    if (failWith case final error?) throw error;
    if (credentials.apiKey == 'bad') {
      throw LastFmException(LastFmErrorCode.invalidApiKey, 'Invalid API key');
    }
    return 'token${++tokens}';
  }

  @override
  Future<LastFmSession> getSession(
    LastFmCredentials credentials,
    String token,
  ) async {
    credentialsSeen.add(credentials);
    if (session case final override?) return override(token);
    if (failWith case final error?) throw error;
    if (expired.contains(token)) {
      throw LastFmException(LastFmErrorCode.tokenExpired, 'Token expired');
    }
    if (!authorized.contains(token)) {
      throw LastFmException(
        LastFmErrorCode.tokenNotAuthorized,
        'This token has not been authorized',
      );
    }
    return const LastFmSession(userName: 'alex', key: 'sk');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const credentials = LastFmCredentials(apiKey: 'key', apiSecret: 'secret');

  late MockSecureStorage storage;
  late _FakeClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = MockSecureStorage();
    client = _FakeClient();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  });

  void stored({String? apiKey, String? apiSecret, String? sessionKey}) {
    when(
      () => storage.read(key: LastFmAccountNotifier.apiKeyKey),
    ).thenAnswer((_) async => apiKey);
    when(
      () => storage.read(key: LastFmAccountNotifier.apiSecretKey),
    ).thenAnswer((_) async => apiSecret);
    when(
      () => storage.read(key: LastFmAccountNotifier.sessionKeyKey),
    ).thenAnswer((_) async => sessionKey);
  }

  ProviderContainer build() => createProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
      lastFmAccountProvider.overrideWith(
        (ref) => LastFmAccountNotifier(ref, client: client),
      ),
    ],
  );

  Future<LastFmAccount> settled(ProviderContainer container) async {
    container.read(lastFmAccountProvider);
    await container.read(sharedPreferencesProvider.future);
    await pumpEventQueue();
    await pumpEventQueue();
    return container.read(lastFmAccountProvider);
  }

  Future<Uri?> begin(
    LastFmAccountNotifier notifier, {
    String apiKey = 'key',
    String apiSecret = 'secret',
  }) => notifier.beginAuthorization(apiKey: apiKey, apiSecret: apiSecret);

  test('starts disconnected when nothing is stored', () async {
    final account = await settled(build());
    expect(account.status, LastFmStatus.disconnected);
  });

  test('beginAuthorization fetches a token with the entered keys', () async {
    final container = build();
    await settled(container);

    final url = await begin(
      container.read(lastFmAccountProvider.notifier),
      apiKey: ' key ',
      apiSecret: 'secret ',
    );

    expect(
      url,
      Uri.parse('https://www.last.fm/api/auth/?api_key=key&token=token1'),
    );
    expect(client.credentialsSeen.single, credentials);
    final account = container.read(lastFmAccountProvider);
    expect(account.status, LastFmStatus.authorizing);
    expect(account.credentials, credentials);
    expect(account.token, 'token1');
  });

  test('beginAuthorization requires both keys', () async {
    final container = build();
    await settled(container);

    final url = await begin(
      container.read(lastFmAccountProvider.notifier),
      apiSecret: '  ',
    );

    expect(url, isNull);
    expect(client.credentialsSeen, isEmpty);
    expect(container.read(lastFmAccountProvider).error, isNotNull);
  });

  test('beginAuthorization reports keys Last.fm rejects', () async {
    final container = build();
    await settled(container);

    final url = await begin(
      container.read(lastFmAccountProvider.notifier),
      apiKey: 'bad',
    );

    expect(url, isNull);
    final account = container.read(lastFmAccountProvider);
    expect(account.status, LastFmStatus.disconnected);
    expect(account.error, 'Last.fm did not accept this API key and secret');
    expect(account.credentials?.apiKey, 'bad');
  });

  test('completeAuthorization stores the keys, session and user', () async {
    final container = build();
    await settled(container);
    final notifier = container.read(lastFmAccountProvider.notifier);
    await begin(notifier);
    client.authorized.add('token1');

    expect(await notifier.completeAuthorization(), isTrue);

    final account = container.read(lastFmAccountProvider);
    expect(account.status, LastFmStatus.connected);
    expect(account.userName, 'alex');
    expect(account.sessionKey, 'sk');
    expect(account.credentials, credentials);
    verify(
      () => storage.write(key: LastFmAccountNotifier.apiKeyKey, value: 'key'),
    ).called(1);
    verify(
      () => storage.write(
        key: LastFmAccountNotifier.apiSecretKey,
        value: 'secret',
      ),
    ).called(1);
    verify(
      () => storage.write(
        key: LastFmAccountNotifier.sessionKeyKey,
        value: 'sk',
      ),
    ).called(1);
    expect(
      container
          .read(appSettingsProvider.notifier)
          .valueOf(AppSetting.lastFmUser),
      'alex',
    );
  });

  test('completeAuthorization keeps waiting while unauthorized', () async {
    final container = build();
    await settled(container);
    final notifier = container.read(lastFmAccountProvider.notifier);
    await begin(notifier);

    expect(await notifier.completeAuthorization(), isFalse);

    final account = container.read(lastFmAccountProvider);
    expect(account.status, LastFmStatus.authorizing);
    expect(account.token, 'token1');
    expect(account.error, contains('not allowed access yet'));
    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );

    client.authorized.add('token1');
    expect(await notifier.completeAuthorization(), isTrue);
  });

  test('an expired token drops back to disconnected', () async {
    final container = build();
    await settled(container);
    final notifier = container.read(lastFmAccountProvider.notifier);
    await begin(notifier);
    client.expired.add('token1');

    expect(await notifier.completeAuthorization(), isFalse);

    final account = container.read(lastFmAccountProvider);
    expect(account.status, LastFmStatus.disconnected);
    expect(account.token, isNull);
    expect(account.credentials, credentials);
    expect(account.error, contains('expired'));
  });

  test('completeAuthorization without a token fails', () async {
    final container = build();
    await settled(container);

    expect(
      await container
          .read(lastFmAccountProvider.notifier)
          .completeAuthorization(),
      isFalse,
    );
    expect(container.read(lastFmAccountProvider).error, isNotNull);
  });

  test('beginAuthorization reports an unreachable Last.fm', () async {
    client.failWith = const ScrobbleException('offline');
    final container = build();
    await settled(container);

    final url = await begin(container.read(lastFmAccountProvider.notifier));

    expect(url, isNull);
    final account = container.read(lastFmAccountProvider);
    expect(account.status, LastFmStatus.disconnected);
    expect(account.error, 'Could not reach Last.fm: offline');
  });

  test('restores a connected account from storage and settings', () async {
    SharedPreferences.setMockInitialValues({
      'app_settings': '{"lastfm_user":"alex"}',
    });
    stored(apiKey: 'key', apiSecret: 'secret', sessionKey: 'stored');

    final account = await settled(build());

    expect(account.status, LastFmStatus.connected);
    expect(account.userName, 'alex');
    expect(account.sessionKey, 'stored');
    expect(account.credentials, credentials);
  });

  test('stays disconnected when a stored key is missing', () async {
    SharedPreferences.setMockInitialValues({
      'app_settings': '{"lastfm_user":"alex"}',
    });
    stored(apiKey: 'key', sessionKey: 'stored');

    final account = await settled(build());

    expect(account.status, LastFmStatus.disconnected);
  });

  test('disconnect forgets the keys, the session and the user', () async {
    stored(apiKey: 'key', apiSecret: 'secret', sessionKey: 'stored');
    SharedPreferences.setMockInitialValues({
      'app_settings': '{"lastfm_user":"alex"}',
    });
    final container = build();
    await settled(container);

    await container.read(lastFmAccountProvider.notifier).disconnect();

    expect(
      container.read(lastFmAccountProvider).status,
      LastFmStatus.disconnected,
    );
    for (final key in [
      LastFmAccountNotifier.apiKeyKey,
      LastFmAccountNotifier.apiSecretKey,
      LastFmAccountNotifier.sessionKeyKey,
    ]) {
      verify(() => storage.delete(key: key)).called(1);
    }
    expect(
      container
          .read(appSettingsProvider.notifier)
          .valueOf(AppSetting.lastFmUser),
      isEmpty,
    );
  });

  test('a slow restore does not overwrite a completed connect', () async {
    final gate = Completer<String?>();
    stored(apiKey: 'key', apiSecret: 'secret');
    when(
      () => storage.read(key: LastFmAccountNotifier.sessionKeyKey),
    ).thenAnswer((_) => gate.future);
    final container = build()..read(lastFmAccountProvider);
    await container.read(sharedPreferencesProvider.future);
    await pumpEventQueue();
    final notifier = container.read(lastFmAccountProvider.notifier);

    await begin(notifier);
    client.authorized.add('token1');
    await notifier.completeAuthorization();
    gate.complete(null);
    await pumpEventQueue();

    final account = container.read(lastFmAccountProvider);
    expect(account.status, LastFmStatus.connected);
    expect(account.userName, 'alex');
  });

  test('a disconnect during connect wins', () async {
    final gate = Completer<LastFmSession>();
    client.session = (_) => gate.future;
    final container = build();
    await settled(container);
    final notifier = container.read(lastFmAccountProvider.notifier);
    await begin(notifier);

    final connecting = notifier.completeAuthorization();
    await notifier.disconnect();
    gate.complete(const LastFmSession(userName: 'alex', key: 'sk'));
    expect(await connecting, isFalse);

    expect(
      container.read(lastFmAccountProvider).status,
      LastFmStatus.disconnected,
    );
    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('markSessionRejected only applies to a connected account', () async {
    final container = build();
    await settled(container);
    final notifier = container.read(lastFmAccountProvider.notifier)
      ..markSessionRejected();
    expect(
      container.read(lastFmAccountProvider).status,
      LastFmStatus.disconnected,
    );
    await begin(notifier);
    client.authorized.add('token1');
    await notifier.completeAuthorization();
    notifier.markSessionRejected();
    expect(
      container.read(lastFmAccountProvider).status,
      LastFmStatus.sessionRejected,
    );
  });
}
