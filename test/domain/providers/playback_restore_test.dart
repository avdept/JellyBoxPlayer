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
import 'package:jplayer/src/data/storages/playback_storage.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/pending_media_play_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeTarget implements PlaybackTarget {
  final _controller = StreamController<TargetPlaybackState>.broadcast();

  int plays = 0;
  bool playOnLoad = false;
  final loads = <({int index, Duration position, bool autoPlay})>[];

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
    loads.add((
      index: initialIndex,
      position: initialPosition,
      autoPlay: autoPlay,
    ));
    _state = TargetPlaybackState(
      status: playOnLoad ? PlaybackStatus.playing : PlaybackStatus.paused,
      position: initialPosition,
      currentIndex: initialIndex,
    );
    _controller.add(_state);
  }

  @override
  Future<void> play() async => plays++;

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
  late int pendingTakes;

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
    final dbDir = await Directory.systemTemp.createTemp('playback_restore_db');
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
    pendingTakes = 0;
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

  ProviderContainer containerWith({required bool pendingPress}) {
    final container = ProviderContainer(
      overrides: [
        localPlaybackTargetProvider.overrideWithValue(target),
        mediaServerClientProvider.overrideWith((_) => client),
        isOfflineProvider.overrideWithValue(false),
        pendingMediaPlayProvider.overrideWithValue(() {
          pendingTakes++;
          return pendingPress;
        }),
      ],
    );
    addTearDown(() async {
      await container.read(playbackProvider.notifier).clear();
      container.dispose();
    });
    return container;
  }

  Future<void> saveQueue() => PlaybackStorage().save(
    songs: songs,
    album: album,
    songId: 'b',
    positionMs: 90000,
  );

  test(
    '- restores the saved queue paused when nothing asked to play',
    () async {
      await saveQueue();
      final container = containerWith(pendingPress: false);

      final restored = await container
          .read(playbackProvider.notifier)
          .tryRestore();

      expect(restored, isTrue);
      expect(target.loads.single.index, 1);
      expect(target.loads.single.position, const Duration(seconds: 90));
      expect(target.loads.single.autoPlay, isFalse);
      expect(target.plays, 0);
      expect(container.read(playbackProvider).status, PlaybackStatus.paused);
    },
  );

  test('- plays the restored queue for a press that woke the app', () async {
    await saveQueue();
    final container = containerWith(pendingPress: true);

    await container.read(playbackProvider.notifier).tryRestore();

    expect(target.plays, 1);
    expect(container.read(playbackProvider).status, PlaybackStatus.playing);
  });

  test('- follows a player that already started during the restore', () async {
    await saveQueue();
    target.playOnLoad = true;
    final container = containerWith(pendingPress: false);

    await container.read(playbackProvider.notifier).tryRestore();

    expect(container.read(playbackProvider).status, PlaybackStatus.playing);
  });

  test('- drops a pending press when there is nothing to restore', () async {
    final container = containerWith(pendingPress: true);

    final restored = await container
        .read(playbackProvider.notifier)
        .tryRestore();

    expect(restored, isFalse);
    expect(pendingTakes, 1);
    expect(target.loads, isEmpty);
    expect(target.plays, 0);
  });
}
