import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/data/storages/playback_storage.dart';
import 'package:jplayer/src/data/storages/resume_point_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/pending_media_play_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/resume_points_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeTarget implements PlaybackTarget {
  final _controller = StreamController<TargetPlaybackState>.broadcast();

  TargetPlaybackState _state = TargetPlaybackState.idle;

  @override
  PlaybackTargetKind get kind => PlaybackTargetKind.local;

  @override
  String get id => 'local';

  @override
  String get name => 'This device';

  @override
  StreamTargetProfile get streamProfile =>
      StreamTargetProfile.localPlayer(isAndroid: false);

  @override
  bool get supportsLocalFiles => true;

  @override
  TargetPlaybackState get state => _state;

  @override
  Stream<TargetPlaybackState> get stateStream => _controller.stream;

  @override
  Future<void> load(
    List<TargetTrack> tracks, {
    required int initialIndex,
    required Duration initialPosition,
    required bool autoPlay,
  }) async {
    emit(
      TargetPlaybackState(
        status: autoPlay ? PlaybackStatus.playing : PlaybackStatus.paused,
        position: initialPosition,
        currentIndex: initialIndex,
      ),
    );
  }

  void emit(TargetPlaybackState state) {
    _state = state;
    _controller.add(state);
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration position) async {
    emit(
      TargetPlaybackState(
        status: _state.status,
        position: position,
        currentIndex: _state.currentIndex,
      ),
    );
  }

  @override
  Future<void> skipTo(int index) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late _FakeTarget target;
  late MediaServerClient client;

  const album = LibraryItem(id: 'album', name: 'Album', kind: ItemKind.album);
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
    final dbDir = await Directory.systemTemp.createTemp('resume_points_pb');
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
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));

    target = _FakeTarget();
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

  ProviderContainer newContainer() {
    final container = ProviderContainer(
      overrides: [
        localPlaybackTargetProvider.overrideWithValue(target),
        mediaServerClientProvider.overrideWith((_) => client),
        isOfflineProvider.overrideWithValue(false),
        pendingMediaPlayProvider.overrideWithValue(() => false),
        currentUserProvider.overrideWith(
          (_) => const User(userId: 'user-1', token: 'token'),
        ),
      ],
    );
    container.read(currentServerIdProvider.notifier).state = 'srv';
    addTearDown(() async {
      await container.read(playbackProvider.notifier).clear();
      container.dispose();
    });
    return container;
  }

  ResumePointDatabase stored() => ResumePointDatabase(
    DownloadDatabase(serverId: 'srv'),
    userId: 'user-1',
  );

  Future<ResumePoint?> settled(ProviderContainer container) async {
    await pumpEventQueue();
    return stored().get(album.id);
  }

  test('- follows the playing song of a queue started from a set', () async {
    final container = newContainer();
    final playback = container.read(playbackProvider.notifier);
    final bumps = <int>[];
    container.listen(resumePointsChangedProvider, (_, n) => bumps.add(n));

    await playback.play(songs.first, songs, album, sourceId: album.id);
    target.emit(
      const TargetPlaybackState(
        status: PlaybackStatus.playing,
        position: Duration(seconds: 40),
        currentIndex: 1,
      ),
    );

    final point = await settled(container);
    expect(point, isNotNull);
    expect(point!.songId, 'b');
    expect(point.songName, 'song b');
    expect(point.songIndex, 1);
    expect(point.songCount, 3);
    expect(point.position, const Duration(seconds: 40));
    expect(point.item.id, album.id);
    expect(bumps, isNotEmpty);
  });

  test('- periodic ticks within 15 s do not rewrite the point', () async {
    final container = newContainer();
    final playback = container.read(playbackProvider.notifier);

    await playback.play(songs.first, songs, album, sourceId: album.id);
    target.emit(
      const TargetPlaybackState(
        status: PlaybackStatus.playing,
        position: Duration(seconds: 40),
        currentIndex: 1,
      ),
    );
    final first = await settled(container);
    await Future<void>.delayed(const Duration(seconds: 6));
    target.emit(
      const TargetPlaybackState(
        status: PlaybackStatus.playing,
        position: Duration(seconds: 46),
        currentIndex: 1,
      ),
    );

    final second = await settled(container);
    expect(first!.position, const Duration(seconds: 40));
    expect(second!.position, const Duration(seconds: 40));

    await playback.seek(const Duration(minutes: 2));

    expect((await settled(container))!.position, const Duration(minutes: 2));
  });

  test('- a queue without a set leaves no point behind', () async {
    final container = newContainer();
    final playback = container.read(playbackProvider.notifier);

    await playback.play(songs.first, songs, album);
    target.emit(
      const TargetPlaybackState(
        status: PlaybackStatus.playing,
        position: Duration(seconds: 40),
        currentIndex: 1,
      ),
    );

    expect(await settled(container), isNull);
  });

  test('- a daily generated mix leaves no point behind', () async {
    const mix = LibraryItem(
      id: 'jellybox:genre-mix:rock:1762000000000',
      name: 'Rock mix',
      kind: ItemKind.playlist,
    );
    final container = newContainer();
    final playback = container.read(playbackProvider.notifier);

    await playback.play(songs.first, songs, mix, sourceId: mix.id);
    target.emit(
      const TargetPlaybackState(
        status: PlaybackStatus.playing,
        position: Duration(seconds: 40),
        currentIndex: 1,
      ),
    );

    await pumpEventQueue();
    expect(await stored().get(mix.id), isNull);
    expect(await stored().all(), isEmpty);
  });

  test('- finishing the queue clears the point', () async {
    final container = newContainer();
    final playback = container.read(playbackProvider.notifier);

    await playback.play(songs.first, songs, album, sourceId: album.id);
    target.emit(
      const TargetPlaybackState(
        status: PlaybackStatus.playing,
        position: Duration(seconds: 40),
        currentIndex: 2,
      ),
    );
    expect(await settled(container), isNotNull);

    target.emit(
      const TargetPlaybackState(
        status: PlaybackStatus.playing,
        position: Duration(minutes: 5),
        currentIndex: 2,
        completed: true,
      ),
    );

    expect(await settled(container), isNull);
  });

  test('- restoring the queue at launch does not refresh the point', () async {
    final old = DateTime.utc(2026, 10, 1);
    await stored().save((
      item: album,
      songId: 'b',
      songName: 'song b',
      songIndex: 1,
      songCount: 3,
      position: const Duration(seconds: 90),
      updatedAt: old,
    ));
    await PlaybackStorage().save(
      serverId: 'srv',
      songs: songs,
      album: album,
      songId: 'b',
      positionMs: 90000,
      sourceId: album.id,
    );
    final container = newContainer();

    final restored = await container
        .read(playbackProvider.notifier)
        .tryRestore();

    expect(restored, isTrue);
    final point = await settled(container);
    expect(point!.updatedAt, old);
  });
}
