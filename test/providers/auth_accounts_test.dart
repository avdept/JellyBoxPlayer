import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/download_service.dart';
import 'package:jplayer/src/data/services/server_data_cleaner.dart';
import 'package:jplayer/src/data/storages/account_store.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/data/backend/server_type.dart';
import 'package:jplayer/src/providers/accounts_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider_container.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class MockDownloadService extends Mock implements DownloadService {}

class StubPlayback extends StateNotifier<PlaybackState>
    implements PlaybackNotifier {
  StubPlayback() : super(PlaybackState.initial());

  int cleared = 0;
  int restores = 0;

  @override
  Future<void> clear() async => cleared++;

  @override
  Future<bool> tryRestore() async {
    restores++;
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordingCleaner extends ServerDataCleaner {
  RecordingCleaner(this.id, this.log) : super(id);

  final String id;
  final List<String> log;

  @override
  Future<void> deleteAll() async => log.add(id);
}

const accountA = ServerAccount(
  serverId: 'A',
  serverType: ServerType.jellyfin,
  url: 'http://a.local',
  userId: 'user-a',
  token: 'token-a',
);

const accountB = ServerAccount(
  serverId: 'B',
  serverType: ServerType.jellyfin,
  url: 'http://b.local',
  userId: 'user-b',
  token: 'token-b',
  userName: 'bea',
  libraryId: 'lib-b',
  libraryName: 'B music',
  relayUrl: 'https://b.tunnel.jellybox.app',
);

Map<String, String> signedInTo(
  ServerAccount active, {
  List<ServerAccount>? accounts,
}) => {
  'serverUrl': active.url,
  'serverType': active.serverType.name,
  'serverId': active.serverId,
  'userId': active.userId,
  'authToken': active.token,
  if (accounts != null)
    AccountStore.storageKey: jsonEncode([
      for (final account in accounts) account.toJson(),
    ]),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClientAdapter adapter;
  late StubPlayback playback;
  late List<String> cleaned;
  late int status;
  late String signInServerId;

  const storage = FlutterSecureStorage();

  setUpAll(() {
    deviceId = 'test-device';
    appInfo = PackageInfo(
      appName: 'JellyBox',
      packageName: 'app.jellybox',
      version: '0.0.0',
      buildNumber: '0',
    );
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(const Stream<Uint8List>.empty());
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    playback = StubPlayback();
    cleaned = [];
    status = 200;
    signInServerId = 'B';
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((
      invocation,
    ) async {
      final options = invocation.positionalArguments.first as RequestOptions;
      final body = options.path.endsWith('/Views')
          ? jsonEncode({
              'Items': [
                {
                  'Id': 'first-lib',
                  'Name': 'First music',
                  'Type': 'CollectionFolder',
                  'CollectionType': 'music',
                },
              ],
              'TotalRecordCount': 1,
            })
          : options.path.contains('AuthenticateByName')
          ? jsonEncode({
              'User': {'Id': 'user-$signInServerId', 'Name': 'alex'},
              'SessionInfo': {
                'Id': 'session-1',
                'PlayState': <String, dynamic>{},
              },
              'AccessToken': 'fresh-token',
              'ServerId': signInServerId,
            })
          : jsonEncode({'Items': <dynamic>[], 'TotalRecordCount': 0});
      return ResponseBody.fromString(
        body,
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
  });

  Future<ProviderContainer> start(
    Map<String, String> secure, {
    Map<String, Object> prefs = const {},
  }) async {
    FlutterSecureStorage.setMockInitialValues(secure);
    SharedPreferences.setMockInitialValues(prefs);
    final downloads = MockDownloadService();
    when(downloads.cancelAll).thenAnswer((_) async {});
    final container = createProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        downloadServiceProvider.overrideWithValue(downloads),
        playbackProvider.overrideWith((ref) => playback),
        serverDataCleanerProvider.overrideWith(
          (ref, serverId) => RecordingCleaner(serverId, cleaned),
        ),
      ],
    );
    container.read(dioProvider).httpClientAdapter = adapter;
    await container.read(sharedPreferencesProvider.future);
    container.read(playbackProvider);
    await container.read(authProvider.future);
    return container;
  }

  ServerAccount accountOf(ProviderContainer container, String serverId) =>
      container
          .read(accountsProvider)
          .firstWhere((account) => account.serverId == serverId);

  group('AuthNotifier accounts', () {
    test('- adopts the signed-in server as the first account', () async {
      final container = await start(
        {...signedInTo(accountA), 'remoteUrl': 'http://remote-a'},
        prefs: {'library_id': 'lib-a', 'library_name': 'A music'},
      );

      final account = accountOf(container, 'A');
      expect(container.read(accountsProvider), hasLength(1));
      expect(account.token, 'token-a');
      expect(account.remoteUrl, 'http://remote-a');
      expect(account.libraryId, 'lib-a');
      expect(await storage.read(key: AccountStore.storageKey), isNotNull);
      expect(await storage.read(key: 'serverId'), 'A');
    });

    test('- remembers a server\'s libraries across restarts', () async {
      final container = await start(
        signedInTo(accountA, accounts: [accountA, accountB]),
      );

      await container.read(authProvider.notifier).rememberLibraries('B', const [
        SavedLibrary(
          id: 'lib-b',
          name: 'B music',
          imageUrl: 'http://b.local/Items/lib-b/Images/Primary',
          imageKey: '/Items/lib-b/Images/Primary',
        ),
      ]);
      final stored = await AccountStore(storage).load();

      final b = stored!.firstWhere((account) => account.serverId == 'B');
      expect(b.libraries.single.name, 'B music');
      expect(b.libraries.single.imageKey, '/Items/lib-b/Images/Primary');
    });

    test('- switching restores the other server and its library', () async {
      final container = await start(
        signedInTo(accountA, accounts: [accountA, accountB]),
        prefs: {
          'library_id': 'lib-a',
          'pb_songs.A': '[]',
          'pb_song_id.A': 's1',
        },
      );

      await container.read(authProvider.notifier).switchTo('B');

      expect(container.read(authProvider).value, isTrue);
      expect(playback.cleared, 1);
      expect(playback.restores, 1);
      expect(container.read(currentServerIdProvider), 'B');
      expect(await storage.read(key: 'authToken'), 'token-b');
      expect(await storage.read(key: 'serverUrl'), 'http://b.local');
      expect(
        await storage.read(key: 'relayUrl'),
        'https://b.tunnel.jellybox.app',
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('library_id'), 'lib-b');
      expect(prefs.getString('pb_songs.A'), '[]');
      expect(accountOf(container, 'A').libraryId, 'lib-a');
    });

    test('- switching to a picked library opens that library', () async {
      final container = await start(
        signedInTo(accountA, accounts: [accountA, accountB]),
      );

      await container
          .read(authProvider.notifier)
          .switchTo(
            'B',
            library: const LibraryItem(
              id: 'lib-b2',
              name: 'B audiobooks',
              kind: ItemKind.library,
            ),
          );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('library_id'), 'lib-b2');
      expect(prefs.getString('library_name'), 'B audiobooks');
      expect(await storage.read(key: 'serverId'), 'B');
    });

    test(
      '- a double-submitted login adds the server once, without an error',
      () async {
        final container = await start(
          signedInTo(accountA, accounts: [accountA]),
        );
        const credentials = UserCredentials(
          username: 'alex',
          pw: 'pw',
          serverUrl: 'http://b.local',
        );

        final auth = container.read(authProvider.notifier);
        final results = await Future.wait([
          auth.login(credentials, serverType: ServerType.jellyfin),
          auth.login(credentials, serverType: ServerType.jellyfin),
        ]);

        expect(results, [null, null]);
        expect(
          container.read(accountsProvider).map((account) => account.serverId),
          ['A', 'B'],
        );
        expect(container.read(authProvider).value, isTrue);
      },
    );

    test('- editing the home address updates the saved account', () async {
      final container = await start(
        signedInTo(accountA, accounts: [accountA, accountB]),
      );

      await container
          .read(authProvider.notifier)
          .updateHomeUrl('http://a.fresh.local');

      expect(accountOf(container, 'A').url, 'http://a.fresh.local');
      expect(accountOf(container, 'B').url, 'http://b.local');
      expect(await storage.read(key: 'serverUrl'), 'http://a.fresh.local');
    });

    test('- refuses to add a server that is already an account', () async {
      final container = await start(
        signedInTo(accountA, accounts: [accountA]),
      );
      signInServerId = 'A';

      final result = await container
          .read(authProvider.notifier)
          .login(
            const UserCredentials(
              username: 'alex',
              pw: 'pw',
              serverUrl: 'http://a.local',
            ),
            serverType: ServerType.jellyfin,
          );

      expect(result, AuthNotifier.alreadyAddedError);
      expect(container.read(accountsProvider), hasLength(1));
      expect(await storage.read(key: 'authToken'), 'token-a');
      expect(container.read(authProvider).value, isTrue);
    });

    test(
      '- adding another server makes it active and keeps the first',
      () async {
        final container = await start(
          signedInTo(accountA, accounts: [accountA]),
        );

        final result = await container
            .read(authProvider.notifier)
            .login(
              const UserCredentials(
                username: 'alex',
                pw: 'pw',
                serverUrl: 'http://b.local',
              ),
              serverType: ServerType.jellyfin,
            );

        expect(result, isNull);
        expect(
          container.read(accountsProvider).map((account) => account.serverId),
          ['A', 'B'],
        );
        expect(accountOf(container, 'B').userName, 'alex');
        expect(await storage.read(key: 'serverId'), 'B');
        expect(await storage.read(key: 'authToken'), 'fresh-token');
        expect(container.read(authProvider).value, isTrue);
      },
    );

    test('- removing a background account deletes only its data', () async {
      final container = await start(
        signedInTo(accountA, accounts: [accountA, accountB]),
      );

      await container.read(authProvider.notifier).removeAccount('B');

      expect(cleaned, ['B']);
      expect(
        container.read(accountsProvider).map((account) => account.serverId),
        ['A'],
      );
      expect(await storage.read(key: 'serverId'), 'A');
      expect(container.read(authProvider).value, isTrue);
    });

    test('- removing the active account moves to the next one', () async {
      final container = await start(
        signedInTo(accountA, accounts: [accountA, accountB]),
      );

      await container.read(authProvider.notifier).removeAccount('A');

      expect(cleaned, ['A']);
      expect(
        container.read(accountsProvider).map((account) => account.serverId),
        ['B'],
      );
      expect(await storage.read(key: 'serverId'), 'B');
      expect(container.read(authProvider).value, isTrue);
    });

    test(
      '- logging out of the active server opens the next one on its first '
      'library when it has none saved',
      () async {
        const accountC = ServerAccount(
          serverId: 'C',
          serverType: ServerType.jellyfin,
          url: 'http://c.local',
          userId: 'user-c',
          token: 'token-c',
        );
        final container = await start(
          signedInTo(accountA, accounts: [accountA, accountC]),
          prefs: {'library_id': 'lib-a'},
        );

        await container.read(authProvider.notifier).removeAccount('A');

        final prefs = await SharedPreferences.getInstance();
        expect(await storage.read(key: 'serverId'), 'C');
        expect(prefs.getString('library_id'), 'first-lib');
        expect(accountOf(container, 'C').libraryId, 'first-lib');
        expect(container.read(authProvider).value, isTrue);
      },
    );

    test(
      '- removing the last account signs out but keeps app-wide tokens',
      () async {
        final container = await start({
          ...signedInTo(accountA, accounts: [accountA]),
          'listenbrainz_token': 'lb',
        });

        await container.read(authProvider.notifier).removeAccount('A');

        expect(container.read(authProvider).value, isFalse);
        expect(container.read(accountsProvider), isEmpty);
        expect(await storage.read(key: 'serverId'), isNull);
        expect(await storage.read(key: 'authToken'), isNull);
        expect(await storage.read(key: 'listenbrainz_token'), 'lb');
      },
    );

    test('- an expired session only signs that server out', () async {
      final container = await start({
        ...signedInTo(accountA, accounts: [accountA, accountB]),
        'listenbrainz_token': 'lb',
      });
      status = 401;

      await expectLater(
        container.read(dioProvider).get<void>('http://a.local/Items'),
        throwsA(isA<DioException>()),
      );
      await pumpEventQueue();

      expect(container.read(authProvider).value, isFalse);
      expect(accountOf(container, 'A').needsReauth, isTrue);
      expect(accountOf(container, 'B').needsReauth, isFalse);
      expect(await storage.read(key: 'authToken'), isNull);
      expect(await storage.read(key: 'listenbrainz_token'), 'lb');
    });

    test('- ignores a 401 from a server that is no longer active', () async {
      final container = await start(
        signedInTo(accountA, accounts: [accountA, accountB]),
      );
      status = 401;

      await expectLater(
        container.read(dioProvider).get<void>('http://b.local/Items'),
        throwsA(isA<DioException>()),
      );
      await pumpEventQueue();

      expect(container.read(authProvider).value, isTrue);
      expect(accountOf(container, 'A').needsReauth, isFalse);
      expect(await storage.read(key: 'authToken'), 'token-a');
    });

    test('- signing in from the login page reuses a saved account', () async {
      final container = await start({
        AccountStore.storageKey: jsonEncode([accountA.toJson()]),
      });
      signInServerId = 'A';

      final result = await container
          .read(authProvider.notifier)
          .login(
            const UserCredentials(
              username: 'alex',
              pw: 'pw',
              serverUrl: 'http://a.local',
            ),
            serverType: ServerType.jellyfin,
          );

      expect(result, isNull);
      expect(container.read(accountsProvider), hasLength(1));
      expect(accountOf(container, 'A').token, 'fresh-token');
      expect(container.read(authProvider).value, isTrue);
    });

    test('- signing in again clears the expired flag', () async {
      final container = await start(
        {
          AccountStore.storageKey: jsonEncode([
            accountA.copyWith(needsReauth: true).toJson(),
          ]),
        },
      );
      signInServerId = 'A';

      final result = await container
          .read(authProvider.notifier)
          .login(
            const UserCredentials(
              username: 'alex',
              pw: 'pw',
              serverUrl: 'http://a.local',
            ),
            serverType: ServerType.jellyfin,
          );

      expect(result, isNull);
      expect(container.read(accountsProvider), hasLength(1));
      expect(accountOf(container, 'A').needsReauth, isFalse);
      expect(accountOf(container, 'A').token, 'fresh-token');
      expect(container.read(authProvider).value, isTrue);
    });
  });
}
