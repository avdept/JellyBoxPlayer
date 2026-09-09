import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/downloads/cache_downloader.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/queue_cache_service.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/queue_cache_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/forward_cache_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeTarget implements PlaybackTarget, SwappableQueue {
  _FakeTarget({this.kind = PlaybackTargetKind.local});

  final _controller = StreamController<TargetPlaybackState>.broadcast();

  final loaded = <List<TargetTrack>>[];
  final replaced = <(int, TargetTrack)>[];

  TargetPlaybackState _state = TargetPlaybackState.idle;

  @override
  final PlaybackTargetKind kind;

  @override
  String get id => 'local';

  @override
  String get name => 'This device';

  @override
  StreamTargetProfile get streamProfile =>
      StreamTargetProfile.localPlayer(isAndroid: false);

  @override
  bool get supportsLocalFiles => kind == PlaybackTargetKind.local;

  @override
  TargetPlaybackState get state => _state;

  @override
  Stream<TargetPlaybackState> get stateStream => _controller.stream;

  void fail() {
    _state = TargetPlaybackState(
      status: PlaybackStatus.error,
      position: _state.position,
      currentIndex: _state.currentIndex,
    );
    _controller.add(_state);
  }

  void moveTo(int index) {
    _state = TargetPlaybackState(
      status: PlaybackStatus.playing,
      position: Duration.zero,
      currentIndex: index,
    );
    _controller.add(_state);
  }

  @override
  Future<void> load(
    List<TargetTrack> tracks, {
    required int initialIndex,
    required Duration initialPosition,
    required bool autoPlay,
  }) async {
    loaded.add(tracks);
  }

  @override
  Future<void> replace(int index, TargetTrack track) async =>
      replaced.add((index, track));

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeDownloader implements CacheDownloader {
  _FakeDownloader(this._directory);

  final Directory _directory;
  final requested = <String>[];
  final cancelled = <String>[];
  final _hanging = <String, Completer<String?>>{};

  int bytes = 1024;
  bool hang = false;

  @override
  Future<String> directoryPath() async => _directory.path;

  @override
  Future<String?> fetch({
    required String id,
    required String url,
    required String fileName,
  }) async {
    requested.add(id);
    if (hang) {
      final completer = Completer<String?>();
      _hanging[id] = completer;
      return completer.future;
    }
    return _write(fileName);
  }

  String _write(String fileName) {
    final file = File(join(_directory.path, fileName));
    file.openSync(mode: FileMode.write)
      ..truncateSync(bytes)
      ..closeSync();
    return file.path;
  }

  @override
  Future<void> cancel(String id) async {
    cancelled.add(id);
    _hanging.remove(id)?.complete(null);
  }
}

class _HookedDownloadDatabase extends DownloadDatabase {

  Future<void> Function()? onNextLookup;

  @override
  Future<bool> isSongDownloaded(String id) async {
    final hook = onNextLookup;
    if (hook != null) {
      onNextLookup = null;
      await hook();
    }
    return super.isSongDownloaded(id);
  }
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory filesDir;
  late ProviderContainer container;
  late _FakeTarget target;
  late _FakeDownloader downloader;
  late MediaServerClient client;

  const album = LibraryItem(
    id: 'album',
    name: 'Album',
    kind: ItemKind.album,
  );
  final songs = [
    for (final id in ['a', 'b', 'c'])
      LibraryItem(
        id: id,
        name: 'song $id',
        kind: ItemKind.song,
        duration: const Duration(minutes: 5),
      ),
  ];

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('forward_cache_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
    registerFallbackValue(songs.first);
    registerFallbackValue(StreamTargetProfile.download(isAndroid: false));
    registerFallbackValue(
      const PlaybackReport(itemId: 'fallback', playSessionId: 'fallback'),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    deviceId = 'test-device';
    filesDir = await Directory.systemTemp.createTemp('forward_cache');
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));

    target = _FakeTarget();
    downloader = _FakeDownloader(filesDir);
    client = _MockMediaServerClient();
    when(
      () => client.resolveStreamSource(
        any(),
        playSessionId: any(named: 'playSessionId'),
        target: any(named: 'target'),
      ),
    ).thenAnswer(
      (_) async => StreamSource(
        uri: Uri.parse('http://server/audio/stream'),
        isHls: false,
        outputContainer: 'flac',
        mimeType: 'audio/flac',
      ),
    );
    when(() => client.reportPlaybackStarted(any())).thenAnswer((_) async {});
    when(() => client.reportPlaybackStopped(any())).thenAnswer((_) async {});
    when(() => client.reportPlaybackProgress(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await container.read(playbackProvider.notifier).clear();
    container.dispose();
    if (filesDir.existsSync()) await filesDir.delete(recursive: true);
  });

  List<Override> overridesFor(
    ForwardCacheLimit limit, {
    DownloadDatabase? downloads,
    ForwardCacheWindow window = ForwardCacheWindow.min30,
  }) => [
    localPlaybackTargetProvider.overrideWithValue(target),
    mediaServerClientProvider.overrideWith((_) => client),
    isOfflineProvider.overrideWithValue(false),
    forwardCacheLimitProvider.overrideWithValue(limit),
    forwardCacheWindowProvider.overrideWithValue(window),
    if (downloads != null)
      downloadDatabaseProvider.overrideWithValue(downloads),
    queueCacheServiceProvider.overrideWith(
      (ref) => QueueCacheService(
        database: ref.watch(queueCacheDatabaseProvider),
        downloads: ref.watch(downloadDatabaseProvider),
        downloader: downloader,
        deviceId: 'test-device',
      ),
    ),
  ];

  ProviderContainer containerWith(
    ForwardCacheLimit limit, {
    DownloadDatabase? downloads,
    ForwardCacheWindow window = ForwardCacheWindow.min30,
  }) => container = ProviderContainer(
    overrides: overridesFor(limit, downloads: downloads, window: window),
  );

  Future<void> pumpUntil(
    bool Function() done, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!done() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> pumpUntilAsync(
    Future<bool> Function() done, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!await done() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  group('ForwardCacheNotifier', () {
    test('- fetches ahead of the playhead, current track last', () async {
      containerWith(ForwardCacheLimit.gb1);
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs[1], songs, album);
      await pumpUntil(() => container.read(forwardCacheProvider).length == 2);
      await settle();

      expect(downloader.requested, ['c', 'b']);
      expect(container.read(forwardCacheProvider), {'b', 'c'});
      expect(downloader.requested, isNot(contains('a')));
    });

    test('- caches nothing while the limit is off', () async {
      containerWith(ForwardCacheLimit.off);
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => downloader.requested.isNotEmpty);

      expect(downloader.requested, isEmpty);
    });

    test('- caches nothing while casting', () async {
      target = _FakeTarget(kind: PlaybackTargetKind.upnp);
      containerWith(ForwardCacheLimit.gb1);
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => downloader.requested.isNotEmpty);

      expect(downloader.requested, isEmpty);
    });

    test('- swaps cached files into the queue behind the player', () async {
      containerWith(ForwardCacheLimit.gb1);
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => target.replaced.length == 2);

      expect([for (final entry in target.replaced) entry.$1], [1, 2]);
      expect(
        [for (final entry in target.replaced) entry.$2.itemId],
        ['b', 'c'],
      );
      expect(
        target.replaced.every((entry) => entry.$2.isLocalFile),
        isTrue,
      );
    });

    test('- swaps the track it was playing once playback moves on', () async {
      containerWith(ForwardCacheLimit.gb1);
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => target.replaced.length == 2);
      expect(
        [for (final entry in target.replaced) entry.$2.itemId],
        isNot(contains('a')),
      );

      target.moveTo(1);
      await pumpUntil(
        () => target.replaced.any((entry) => entry.$2.itemId == 'a'),
      );

      final adopted = target.replaced.lastWhere(
        (entry) => entry.$2.itemId == 'a',
      );
      expect(adopted.$1, 0);
      expect(adopted.$2.isLocalFile, isTrue);
    });

    test('- keeps the playing queue when the limit is switched off', () async {
      containerWith(ForwardCacheLimit.gb1);
      container.read(forwardCacheProvider.notifier);
      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => container.read(forwardCacheProvider).length == 3);

      container.updateOverrides(overridesFor(ForwardCacheLimit.off));
      await settle();

      final database = container.read(queueCacheDatabaseProvider);
      expect(await database.cachedIds(), {'a', 'b', 'c'});

      const other = LibraryItem(
        id: 'd',
        name: 'song d',
        kind: ItemKind.song,
      );
      await container
          .read(playbackProvider.notifier)
          .play(other, const [other], album);
      await pumpUntilAsync(() async => (await database.cachedIds()).isEmpty);

      expect(await database.cachedIds(), isEmpty);
    });

    test('- evicts the old queue so a new one can still cache', () async {
      containerWith(ForwardCacheLimit.mb500);
      downloader.bytes = 300 * 1024 * 1024;
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => container.read(forwardCacheProvider).length == 2);

      const next = LibraryItem(id: 'd', name: 'song d', kind: ItemKind.song);
      await container
          .read(playbackProvider.notifier)
          .play(next, const [next], album);
      await pumpUntil(
        () => container.read(forwardCacheProvider).contains('d'),
      );

      expect(container.read(forwardCacheProvider), contains('d'));
      expect(container.read(forwardCacheProvider), isNot(contains('a')));
    });

    test('- caches again after the OS reclaims the files', () async {
      containerWith(ForwardCacheLimit.mb500);
      downloader.bytes = 300 * 1024 * 1024;
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => container.read(forwardCacheProvider).length == 2);
      for (final file in filesDir.listSync().whereType<File>()) {
        file.deleteSync();
      }

      downloader.bytes = 1024;
      target.moveTo(1);
      await pumpUntil(
        () => container.read(forwardCacheProvider).contains('c'),
      );

      expect(container.read(forwardCacheProvider), contains('c'));
    });

    test('- only fetches as far ahead as the window allows', () async {
      containerWith(ForwardCacheLimit.gb1, window: ForwardCacheWindow.min10);
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => container.read(forwardCacheProvider).length == 2);
      await settle();

      expect(container.read(forwardCacheProvider), {'a', 'b'});
      expect(downloader.requested, isNot(contains('c')));
    });

    test('- pulls in the next track as playback advances', () async {
      containerWith(ForwardCacheLimit.gb1, window: ForwardCacheWindow.min10);
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => container.read(forwardCacheProvider).length == 2);

      target.moveTo(1);
      await pumpUntil(
        () => container.read(forwardCacheProvider).contains('c'),
      );

      expect(container.read(forwardCacheProvider), {'a', 'b', 'c'});
    });

    test('- keeps played tracks while there is room', () async {
      containerWith(ForwardCacheLimit.gb1, window: ForwardCacheWindow.min10);
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => container.read(forwardCacheProvider).length == 2);

      target.moveTo(2);
      await pumpUntil(
        () => container.read(forwardCacheProvider).contains('c'),
      );

      expect(container.read(forwardCacheProvider), {'a', 'b', 'c'});
    });

    test('- evicts what was played long ago to keep filling', () async {
      final longQueue = [
        for (final id in ['a', 'b', 'c', 'd', 'e', 'f'])
          LibraryItem(
            id: id,
            name: 'song $id',
            kind: ItemKind.song,
            duration: const Duration(minutes: 5),
          ),
      ];
      containerWith(ForwardCacheLimit.mb500, window: ForwardCacheWindow.min10);
      downloader.bytes = 300 * 1024 * 1024;
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(longQueue.first, longQueue, album);
      await pumpUntil(() => container.read(forwardCacheProvider).length == 2);
      expect(container.read(forwardCacheProvider), {'a', 'b'});

      target.moveTo(4);
      await pumpUntil(
        () => container.read(forwardCacheProvider).contains('e'),
      );

      expect(container.read(forwardCacheProvider), contains('e'));
      expect(container.read(forwardCacheProvider), isNot(contains('a')));
    });

    test('- cancels an in-flight fetch when asked to stop', () async {
      containerWith(ForwardCacheLimit.gb1);
      downloader.hang = true;
      final notifier = container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => downloader.requested.isNotEmpty);

      await notifier.cancelPending();
      final requested = downloader.requested.length;
      await settle();

      expect(downloader.cancelled, contains('b'));
      expect(await container.read(queueCacheDatabaseProvider).cachedIds(),
          isEmpty);
      expect(downloader.requested, hasLength(requested));
    });

    test('- cancels an in-flight fetch when switched off', () async {
      containerWith(ForwardCacheLimit.gb1);
      downloader.hang = true;
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => downloader.requested.isNotEmpty);

      container.updateOverrides(overridesFor(ForwardCacheLimit.off));
      await pumpUntil(() => downloader.cancelled.isNotEmpty);

      expect(downloader.cancelled, contains('b'));
    });

    test('- starts a fresh queue straight from the cache', () async {
      containerWith(ForwardCacheLimit.gb1);
      container.read(forwardCacheProvider.notifier);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      await pumpUntil(() => container.read(forwardCacheProvider).length == 3);

      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);

      final tracks = target.loaded.last;
      expect(tracks.every((track) => track.isLocalFile), isTrue);
    });
  });

  group('adoptCachedFiles', () {
    late _HookedDownloadDatabase downloads;
    late QueueCacheDatabase database;
    late PlaybackNotifier playback;

    setUp(() {
      downloads = _HookedDownloadDatabase();
      containerWith(ForwardCacheLimit.off, downloads: downloads);
      database = container.read(queueCacheDatabaseProvider);
      playback = container.read(playbackProvider.notifier);
    });

    Future<Map<String, String>> seedCache(List<LibraryItem> items) async {
      final paths = <String, String>{};
      for (final item in items) {
        final file = File(join(filesDir.path, '${item.id}.flac'))
          ..writeAsBytesSync(List.filled(16, 0));
        await database.insert(item, file: file);
        paths[item.id] = file.path;
      }
      return paths;
    }

    test('- swaps every queue entry but the playing one', () async {
      await playback.play(songs.first, songs, album);
      final paths = await seedCache([songs[1], songs[2]]);

      await playback.adoptCachedFiles(paths);

      expect([for (final entry in target.replaced) entry.$1], [1, 2]);
    });

    test('- runs one at a time when called concurrently', () async {
      await playback.play(songs.first, songs, album);
      final paths = await seedCache([songs[1], songs[2]]);

      await Future.wait([
        playback.adoptCachedFiles(paths),
        playback.adoptCachedFiles(paths),
      ]);

      expect([for (final entry in target.replaced) entry.$1], [1, 2]);
    });

    test('- leaves a track that started playing mid-run alone', () async {
      await playback.play(songs.first, songs, album);
      final paths = await seedCache([songs[1], songs[2]]);
      downloads.onNextLookup = () async {
        target.moveTo(1);
        await Future<void>.delayed(Duration.zero);
      };

      await playback.adoptCachedFiles(paths);

      expect([for (final entry in target.replaced) entry.$1], [2]);
    });

    test('- restreams a track whose cached file vanished', () async {
      await playback.play(songs.first, songs, album);
      final paths = await seedCache([songs[1], songs[2]]);
      await playback.adoptCachedFiles(paths);
      target.moveTo(1);
      await Future<void>.delayed(Duration.zero);
      await File(paths['b']!).delete();
      final loads = target.loaded.length;

      target.fail();
      await pumpUntil(() => target.loaded.length > loads);

      final reloaded = target.loaded.last;
      expect(reloaded[1].itemId, 'b');
      expect(reloaded[1].uri.scheme, 'http');
      expect(reloaded[2].uri.scheme, 'file');
      expect(await database.cachedIds(), isNot(contains('b')));
      expect(
        container.read(playbackProvider).status,
        isNot(PlaybackStatus.error),
      );
    });

    test('- surfaces the error when the file is still there', () async {
      await playback.play(songs.first, songs, album);
      final paths = await seedCache([songs[1], songs[2]]);
      await playback.adoptCachedFiles(paths);
      target.moveTo(1);
      await Future<void>.delayed(Duration.zero);

      target.fail();
      await pumpUntil(
        () => container.read(playbackProvider).status == PlaybackStatus.error,
      );

      expect(container.read(playbackProvider).status, PlaybackStatus.error);
    });
  });
}
