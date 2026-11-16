import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/fanart/fanart_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/fanart_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider_container.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _FakeClient extends FanartClient {
  _FakeClient() : super(userAgent: 'test', linkUrl: 'https://link.test');

  final validated = <FanartCredentials>[];
  final fetched = <(String, FanartCredentials)>[];
  FanartFailure? failWith;

  @override
  Future<void> validate(FanartCredentials credentials) async {
    validated.add(credentials);
    if (failWith case final failure?) {
      throw FanartException(failure, 'failed');
    }
  }

  @override
  Future<FanartArtistImages> artist(
    String musicBrainzId,
    FanartCredentials credentials,
  ) async {
    fetched.add((musicBrainzId, credentials));
    return const FanartArtistImages(
      backgrounds: [FanartImage(id: '1', url: 'https://img/bg.jpg')],
    );
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

  void stored({String? apiKey, String? clientKey}) {
    when(
      () => storage.read(key: FanartAccountNotifier.apiKeyKey),
    ).thenAnswer((_) async => apiKey);
    when(
      () => storage.read(key: FanartAccountNotifier.clientKeyKey),
    ).thenAnswer((_) async => clientKey);
  }

  ProviderContainer build() => createProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
      fanartClientProvider.overrideWithValue(client),
      fanartAccountProvider.overrideWith(
        (ref) => FanartAccountNotifier(ref, client: client),
      ),
    ],
  );

  Future<FanartAccount> settled(ProviderContainer container) async {
    container.read(fanartAccountProvider);
    await container.read(sharedPreferencesProvider.future);
    await pumpEventQueue();
    return container.read(fanartAccountProvider);
  }

  test('uses Jellybox Link when no key is stored', () async {
    final account = await settled(build());
    expect(account.status, FanartStatus.link);
    expect(account.credentials, FanartCredentials.none);
  });

  test('restores stored keys', () async {
    stored(apiKey: 'project', clientKey: 'me');

    final account = await settled(build());

    expect(account.status, FanartStatus.ownKeys);
    expect(
      account.credentials,
      const FanartCredentials(apiKey: 'project', clientKey: 'me'),
    );
  });

  test('a personal key alone still counts as own keys', () async {
    stored(clientKey: 'me');

    final account = await settled(build());

    expect(account.usesOwnKeys, isTrue);
    expect(account.credentials, const FanartCredentials(clientKey: 'me'));
  });

  test('useKeys checks the keys, stores them and switches over', () async {
    final container = build();
    await settled(container);

    final ok = await container
        .read(fanartAccountProvider.notifier)
        .useKeys(apiKey: ' project ', clientKey: ' ');

    expect(ok, isTrue);
    expect(client.validated.single, const FanartCredentials(apiKey: 'project'));
    verify(
      () =>
          storage.write(key: FanartAccountNotifier.apiKeyKey, value: 'project'),
    ).called(1);
    verify(
      () => storage.delete(key: FanartAccountNotifier.clientKeyKey),
    ).called(1);
    expect(container.read(fanartAccountProvider).usesOwnKeys, isTrue);
    expect(
      container.read(fanartCredentialsProvider),
      const FanartCredentials(apiKey: 'project'),
    );
  });

  test('rejected keys are not stored and leave Link in use', () async {
    final container = build();
    await settled(container);
    client.failWith = FanartFailure.badKey;

    final ok = await container
        .read(fanartAccountProvider.notifier)
        .useKeys(apiKey: 'bad');

    expect(ok, isFalse);
    final account = container.read(fanartAccountProvider);
    expect(account.status, FanartStatus.rejected);
    expect(account.error, 'fanart.tv rejected these keys');
    expect(container.read(fanartCredentialsProvider), FanartCredentials.none);
    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });

  test('saving empty keys goes back to Jellybox Link', () async {
    stored(apiKey: 'project');
    final container = build();
    await settled(container);

    final ok = await container
        .read(fanartAccountProvider.notifier)
        .useKeys(apiKey: ' ');

    expect(ok, isTrue);
    expect(client.validated, isEmpty);
    expect(container.read(fanartAccountProvider).status, FanartStatus.link);
    verify(
      () => storage.delete(key: FanartAccountNotifier.apiKeyKey),
    ).called(1);
    verify(
      () => storage.delete(key: FanartAccountNotifier.clientKeyKey),
    ).called(1);
  });

  group('artist images', () {
    const artist = LibraryItem(
      id: 'a1',
      name: 'Radiohead',
      kind: ItemKind.artist,
      externalIds: {ExternalIdProvider.musicBrainzArtist: 'mbid-1'},
    );

    test('are fetched by MusicBrainz id without any keys', () async {
      final container = build();
      await settled(container);

      final images = await container.read(
        fanartArtistImagesProvider(fanartArtistId(artist)!).future,
      );

      expect(client.fetched, [('mbid-1', FanartCredentials.none)]);
      expect(images.backgrounds.single.uri, Uri.parse('https://img/bg.jpg'));
      expect(container.read(fanartArtistBackgroundsProvider), isTrue);
    });

    test('carry the own keys once stored', () async {
      stored(apiKey: 'project');
      final container = build();
      await settled(container);

      await container.read(fanartArtistImagesProvider('mbid-1').future);

      expect(client.fetched, [
        ('mbid-1', const FanartCredentials(apiKey: 'project')),
      ]);
    });

    test('backgrounds switch off with the setting', () async {
      final container = build();
      await settled(container);

      container
          .read(appSettingsProvider.notifier)
          .setEnabled(AppSetting.fanartArtistBackgrounds, value: false);

      expect(container.read(fanartArtistBackgroundsProvider), isFalse);
    });

    test('artists without a MusicBrainz id have no fanart id', () {
      const artist = LibraryItem(id: 'a2', name: 'X', kind: ItemKind.artist);
      expect(fanartArtistId(artist), isNull);
    });
  });
}
