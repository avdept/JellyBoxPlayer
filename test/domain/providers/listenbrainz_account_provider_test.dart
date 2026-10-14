import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_client.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/listenbrainz_account_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider_container.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeClient extends ListenBrainzClient {
  final users = <String, String>{'good': 'alex'};
  final apiUrls = <String>[];
  ScrobbleException? failWith;
  Future<String> Function(String token)? validate;

  @override
  Future<String> validateToken(
    String token, {
    String apiUrl = ListenBrainzClient.defaultApiUrl,
  }) async {
    apiUrls.add(apiUrl);
    if (validate case final override?) return override(token);
    if (apiUrl.contains('jellyfin')) {
      throw NotListenBrainzServerException(apiUrl);
    }
    if (failWith case final error?) throw error;
    final user = users[token];
    if (user == null) {
      throw ScrobbleException.fromStatus(401, 'Invalid token');
    }
    return user;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  ProviderContainer build() {
    final container = createProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        listenBrainzAccountProvider.overrideWith(
          (ref) => ListenBrainzAccountNotifier(ref, client: client),
        ),
      ],
    );
    return container;
  }

  Future<ListenBrainzAccount> settled(ProviderContainer container) async {
    container.read(listenBrainzAccountProvider);
    await container.read(sharedPreferencesProvider.future);
    await pumpEventQueue();
    await pumpEventQueue();
    return container.read(listenBrainzAccountProvider);
  }

  test('starts disconnected when nothing is stored', () async {
    final container = build();
    final account = await settled(container);
    expect(account.status, ListenBrainzStatus.disconnected);
  });

  test('connect validates, stores the token and remembers the user', () async {
    final container = build();
    await settled(container);

    final ok = await container
        .read(listenBrainzAccountProvider.notifier)
        .connect(' good ');

    expect(ok, isTrue);
    final account = container.read(listenBrainzAccountProvider);
    expect(account.status, ListenBrainzStatus.connected);
    expect(account.userName, 'alex');
    expect(account.token, 'good');
    verify(
      () => storage.write(
        key: ListenBrainzAccountNotifier.tokenKey,
        value: 'good',
      ),
    ).called(1);
    final settings = container.read(appSettingsProvider.notifier);
    expect(settings.valueOf(AppSetting.listenBrainzUser), 'alex');
  });

  test('connect validates against a custom API URL and remembers it', () async {
    final container = build();
    await settled(container);

    final ok = await container
        .read(listenBrainzAccountProvider.notifier)
        .connect('good', apiUrl: 'lb.example.com/1/');

    expect(ok, isTrue);
    expect(client.apiUrls.single, 'https://lb.example.com');
    expect(
      container.read(listenBrainzAccountProvider).apiUrl,
      'https://lb.example.com',
    );
    expect(
      container
          .read(appSettingsProvider.notifier)
          .valueOf(AppSetting.listenBrainzApiUrl),
      'https://lb.example.com',
    );
  });

  test('connect rejects an invalid API URL without calling it', () async {
    final container = build();
    await settled(container);

    final ok = await container
        .read(listenBrainzAccountProvider.notifier)
        .connect('good', apiUrl: 'ftp://lb.example.com');

    expect(ok, isFalse);
    expect(client.apiUrls, isEmpty);
    expect(container.read(listenBrainzAccountProvider).error, isNotNull);
  });

  test('connect reports an address that is not ListenBrainz', () async {
    final container = build();
    await settled(container);

    final ok = await container
        .read(listenBrainzAccountProvider.notifier)
        .connect('good', apiUrl: 'https://jellyfin.home');

    expect(ok, isFalse);
    expect(
      container.read(listenBrainzAccountProvider).error,
      'https://jellyfin.home is not a ListenBrainz server',
    );
    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('connect reports a rejected token without storing it', () async {
    final container = build();
    await settled(container);

    final ok = await container
        .read(listenBrainzAccountProvider.notifier)
        .connect('bad');

    expect(ok, isFalse);
    final account = container.read(listenBrainzAccountProvider);
    expect(account.status, ListenBrainzStatus.disconnected);
    expect(account.error, contains('did not accept'));
    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('connect requires a token', () async {
    final container = build();
    await settled(container);
    final ok = await container
        .read(listenBrainzAccountProvider.notifier)
        .connect('   ');
    expect(ok, isFalse);
    expect(container.read(listenBrainzAccountProvider).error, isNotNull);
  });

  test('restores a connected account from storage and settings', () async {
    SharedPreferences.setMockInitialValues({
      'app_settings': '{"listenbrainz_user":"alex"}',
    });
    when(
      () => storage.read(key: ListenBrainzAccountNotifier.tokenKey),
    ).thenAnswer((_) async => 'stored');

    final account = await settled(build());

    expect(account.status, ListenBrainzStatus.connected);
    expect(account.userName, 'alex');
    expect(account.token, 'stored');
    expect(account.apiUrl, ListenBrainzClient.defaultApiUrl);
  });

  test('restores a custom API URL', () async {
    SharedPreferences.setMockInitialValues({
      'app_settings':
          '{"listenbrainz_user":"alex",'
          '"listenbrainz_api_url":"https://lb.example.com"}',
    });
    when(
      () => storage.read(key: ListenBrainzAccountNotifier.tokenKey),
    ).thenAnswer((_) async => 'stored');

    final account = await settled(build());

    expect(account.status, ListenBrainzStatus.connected);
    expect(account.apiUrl, 'https://lb.example.com');
  });

  test('disconnect forgets the token and the user', () async {
    when(
      () => storage.read(key: ListenBrainzAccountNotifier.tokenKey),
    ).thenAnswer((_) async => 'stored');
    SharedPreferences.setMockInitialValues({
      'app_settings':
          '{"listenbrainz_user":"alex",'
          '"listenbrainz_api_url":"https://lb.example.com"}',
    });
    final container = build();
    await settled(container);

    await container.read(listenBrainzAccountProvider.notifier).disconnect();

    expect(
      container.read(listenBrainzAccountProvider).status,
      ListenBrainzStatus.disconnected,
    );
    verify(
      () => storage.delete(key: ListenBrainzAccountNotifier.tokenKey),
    ).called(1);
    expect(
      container
          .read(appSettingsProvider.notifier)
          .valueOf(AppSetting.listenBrainzUser),
      isEmpty,
    );
    expect(
      container
          .read(appSettingsProvider.notifier)
          .valueOf(AppSetting.listenBrainzApiUrl),
      isEmpty,
    );
  });

  test('a slow restore does not overwrite a completed connect', () async {
    final gate = Completer<String?>();
    when(
      () => storage.read(key: ListenBrainzAccountNotifier.tokenKey),
    ).thenAnswer((_) => gate.future);
    final container = build()..read(listenBrainzAccountProvider);
    await container.read(sharedPreferencesProvider.future);
    await pumpEventQueue();

    await container.read(listenBrainzAccountProvider.notifier).connect('good');
    gate.complete(null);
    await pumpEventQueue();

    final account = container.read(listenBrainzAccountProvider);
    expect(account.status, ListenBrainzStatus.connected);
    expect(account.userName, 'alex');
  });

  test('a disconnect during connect wins', () async {
    final gate = Completer<String>();
    client.validate = (_) => gate.future;
    final container = build();
    await settled(container);
    final notifier = container.read(listenBrainzAccountProvider.notifier);

    final connecting = notifier.connect('good');
    await notifier.disconnect();
    gate.complete('alex');
    expect(await connecting, isFalse);

    expect(
      container.read(listenBrainzAccountProvider).status,
      ListenBrainzStatus.disconnected,
    );
    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('markTokenRejected only applies to a connected account', () async {
    final container = build();
    await settled(container);
    final notifier = container.read(listenBrainzAccountProvider.notifier)
      ..markTokenRejected();
    expect(
      container.read(listenBrainzAccountProvider).status,
      ListenBrainzStatus.disconnected,
    );
    await notifier.connect('good');
    notifier.markTokenRejected();
    expect(
      container.read(listenBrainzAccountProvider).status,
      ListenBrainzStatus.tokenRejected,
    );
  });
}
