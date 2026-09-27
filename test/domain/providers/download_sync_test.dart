import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/download_service.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:jplayer/src/providers/network_type_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockDownloadService extends Mock implements DownloadService {}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

class _SwitchableNetwork extends NetworkTypeNotifier {
  _SwitchableNetwork(NetworkType initial) : super(hasCellular: false) {
    state = initial;
  }

  void use(NetworkType type) => state = type;
}

LibraryItem _song(String id) =>
    LibraryItem(id: id, name: 'Song $id', kind: ItemKind.song, albumId: 'al');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const playlist = LibraryItem(
    id: 'pl',
    name: 'Road trip',
    kind: ItemKind.playlist,
  );

  late Directory filesDir;
  late DownloadDatabase database;
  late _MockDownloadService service;
  late _MockMediaServerClient client;
  late _SwitchableNetwork network;
  late List<LibraryItem> serverSongs;
  late List<String> fetched;
  Future<void> Function(LibraryItem song)? onDownload;

  setUpAll(() {
    registerFallbackValue(_song('fallback'));
    registerFallbackValue(ImageKind.primary);
    registerFallbackValue(_MockMediaServerClient());
  });

  setUp(() async {
    deviceId = 'test-device';
    SharedPreferences.setMockInitialValues({});
    filesDir = await Directory.systemTemp.createTemp('download_sync_test');
    await databaseFactory.setDatabasesPath(join(filesDir.path, 'db'));
    database = DownloadDatabase(serverId: 'server');
    service = _MockDownloadService();
    client = _MockMediaServerClient();
    network = _SwitchableNetwork(NetworkType.wifi);
    serverSongs = [];
    fetched = [];
    onDownload = null;

    when(
      () =>
          service.downloadSong(any(), any(), deviceId: any(named: 'deviceId')),
    ).thenAnswer((invocation) async {
      final song = invocation.positionalArguments.first as LibraryItem;
      fetched.add(song.id);
      await onDownload?.call(song);
      final file = File(join(filesDir.path, '${song.id}.flac'))
        ..writeAsBytesSync([1, 2, 3]);
      return DownloadTask(
        id: song.id,
        name: song.name,
        url: 'http://server/${song.id}',
        destination: file.path,
      )..status.value = DownloadStatus.completed;
    });
    when(
      () => service.downloadAlbumCover(any(), any()),
    ).thenAnswer((_) async => null);
    when(() => service.cancelDownload(any())).thenAnswer((_) async {});
    when(
      () => client.imageUri(any(), kind: any(named: 'kind')),
    ).thenReturn(null);
    when(() => client.getPlaylistSongs(any())).thenAnswer(
      (_) async => LibraryPage(items: serverSongs),
    );
  });

  tearDown(() async {
    if (filesDir.existsSync()) await filesDir.delete(recursive: true);
  });

  ProviderContainer createContainer({String? settings}) {
    if (settings != null) {
      SharedPreferences.setMockInitialValues({'app_settings': settings});
    }
    final container = ProviderContainer(
      overrides: [
        downloadServiceProvider.overrideWith((_) => service),
        downloadDatabaseProvider.overrideWithValue(database),
        mediaServerClientProvider.overrideWith((_) => client),
        isOfflineProvider.overrideWithValue(false),
        networkTypeProvider.overrideWith((_) => network),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> downloadPlaylist(
    ProviderContainer container,
    List<String> ids,
  ) async {
    await container
        .read(downloadManagerProvider.notifier)
        .downloadPlaylist(playlist, ids.map(_song).toList());
    fetched.clear();
  }

  Future<List<String>> localIds() async => [
    for (final song in await database.getDownloadedPlaylistSongs(playlist.id))
      song.item.id,
  ];

  group('DownloadManagerNotifier.syncPlaylist', () {
    test('- downloads only the songs added on the server', () async {
      final container = createContainer();
      await downloadPlaylist(container, ['a', 'b']);

      final changed = await container
          .read(downloadManagerProvider.notifier)
          .syncPlaylist(playlist, ['a', 'c', 'b'].map(_song).toList());

      expect(changed, isTrue);
      expect(fetched, ['c']);
      expect(await localIds(), ['a', 'c', 'b']);
    });

    test('- deletes songs removed on the server', () async {
      final container = createContainer();
      await downloadPlaylist(container, ['a', 'b']);
      final removedFile = await database.getDownloadedSongPath('b');

      await container.read(downloadManagerProvider.notifier).syncPlaylist(
        playlist,
        [_song('a')],
      );

      expect(await localIds(), ['a']);
      expect(await database.isSongDownloaded('b'), isFalse);
      expect(File(removedFile!).existsSync(), isFalse);
    });

    test('- keeps a removed song another playlist still has', () async {
      final container = createContainer();
      await downloadPlaylist(container, ['a', 'b']);
      final other = playlist.copyWith(id: 'other');
      await container.read(downloadManagerProvider.notifier).downloadPlaylist(
        other,
        [_song('b')],
      );

      await container.read(downloadManagerProvider.notifier).syncPlaylist(
        playlist,
        [_song('a')],
      );

      expect(await localIds(), ['a']);
      expect(await database.isSongDownloaded('b'), isTrue);
    });

    test('- does nothing when the playlist is unchanged', () async {
      final container = createContainer();
      await downloadPlaylist(container, ['a', 'b']);

      final changed = await container
          .read(downloadManagerProvider.notifier)
          .syncPlaylist(playlist, ['a', 'b'].map(_song).toList());

      expect(changed, isFalse);
      expect(fetched, isEmpty);
    });

    test('- stops a download when the playlist is removed', () async {
      final container = createContainer();
      final manager = container.read(downloadManagerProvider.notifier);
      onDownload = (song) async {
        if (song.id == 'b') await manager.deletePlaylist(playlist.id);
      };

      await manager.downloadPlaylist(
        playlist,
        ['a', 'b', 'c'].map(_song).toList(),
      );

      expect(fetched, ['a', 'b']);
      expect(await database.isPlaylistDownloaded(playlist.id), isFalse);
      expect(await database.getDownloadedSongs(), isEmpty);
      expect(
        filesDir.listSync().whereType<File>().where((f) {
          return f.path.endsWith('a.flac');
        }),
        isEmpty,
      );
    });

    test('- stops a sync when the playlist is removed', () async {
      final container = createContainer();
      await downloadPlaylist(container, ['a']);
      final manager = container.read(downloadManagerProvider.notifier);
      onDownload = (song) async {
        if (song.id == 'b') await manager.deletePlaylist(playlist.id);
      };

      await manager.syncPlaylist(playlist, ['a', 'b', 'c'].map(_song).toList());

      expect(fetched, ['b']);
      expect(await database.isPlaylistDownloaded(playlist.id), isFalse);
      expect(await database.getDownloadedSongs(), isEmpty);
    });
  });

  group('DownloadSync', () {
    Future<void> settle() async {
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    Future<ProviderContainer> signedIn({String? settings}) async {
      final container = createContainer(settings: settings);
      await container.read(sharedPreferencesProvider.future);
      await downloadPlaylist(container, ['a']);
      container.read(currentServerIdProvider.notifier).state = 'server';
      container.read(currentUserProvider.notifier).state = const User(
        userId: 'user',
        token: 'token',
      );
      return container;
    }

    test('- pulls new songs into downloaded playlists on start', () async {
      final container = await signedIn();
      serverSongs = ['a', 'b'].map(_song).toList();

      container.read(downloadSyncProvider);
      await settle();

      expect(fetched, ['b']);
      expect(await localIds(), ['a', 'b']);
    });

    test('- waits for Wi-Fi unless cellular sync is allowed', () async {
      network.use(NetworkType.cellular);
      final container = await signedIn();
      serverSongs = ['a', 'b'].map(_song).toList();

      container.read(downloadSyncProvider);
      await settle();
      expect(fetched, isEmpty);

      network.use(NetworkType.wifi);
      await settle();
      expect(fetched, ['b']);
    });

    test('- syncs on cellular when the setting allows it', () async {
      network.use(NetworkType.cellular);
      final container = await signedIn(
        settings: jsonEncode({AppSetting.downloadSyncOnCellular.key: true}),
      );
      serverSongs = ['a', 'b'].map(_song).toList();

      container.read(downloadSyncProvider);
      await settle();

      expect(fetched, ['b']);
    });

    test(
      '- leaves the download alone when the server returns nothing',
      () async {
        final container = await signedIn();

        container.read(downloadSyncProvider);
        await settle();

        expect(await localIds(), ['a']);
      },
    );

    test('- syncs a playlist right after an in-app edit', () async {
      final container = await signedIn();
      container.read(downloadSyncProvider);
      await settle();

      serverSongs = ['a', 'b'].map(_song).toList();
      container.read(downloadSyncProvider).syncPlaylist(playlist.id);
      await settle();

      expect(fetched, ['b']);
    });
  });
}
