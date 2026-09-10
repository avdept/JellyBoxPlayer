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
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeTarget implements PlaybackTarget {
  final _controller = StreamController<TargetPlaybackState>.broadcast();

  final loaded = <List<TargetTrack>>[];
  final reordered = <({List<TargetTrack> tracks, List<int> order, int at})>[];
  final inserted = <(int, TargetTrack)>[];

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
  Future<void> reorder(
    List<TargetTrack> tracks, {
    required List<int> order,
    required int currentIndex,
  }) async {
    reordered.add((tracks: tracks, order: order, at: currentIndex));
  }

  @override
  Future<void> insert(
    int index,
    TargetTrack track, {
    bool playNext = false,
  }) async {
    inserted.add((index, track));
  }

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

  late ProviderContainer container;
  late _FakeTarget target;
  late MediaServerClient client;

  const album = LibraryItem(
    id: 'album',
    name: 'Album',
    kind: ItemKind.album,
  );
  final songs = [
    for (final id in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'])
      LibraryItem(
        id: id,
        name: 'song $id',
        kind: ItemKind.song,
        duration: const Duration(minutes: 5),
      ),
  ];

  List<String> idsOf(List<LibraryItem> items) => [
    for (final item in items) item.id,
  ];

  List<String> trackIdsOf(List<TargetTrack> tracks) => [
    for (final track in tracks) track.itemId,
  ];

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('playback_shuffle_db');
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

    container = ProviderContainer(
      overrides: [
        localPlaybackTargetProvider.overrideWithValue(target),
        mediaServerClientProvider.overrideWith((_) => client),
        isOfflineProvider.overrideWithValue(false),
      ],
    );
  });

  tearDown(() async {
    await container.read(playbackProvider.notifier).clear();
    container.dispose();
  });

  test('- shuffling keeps the playing song and reorders the rest', () async {
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs[3], songs, album);

    await playback.setShuffle(enabled: true);

    final state = container.read(playbackProvider);
    expect(state.shuffleEnabled, isTrue);
    expect(state.currentMediaIndex, 0);
    expect(state.songs.first.id, 'd');
    expect(idsOf(state.songs), unorderedEquals(idsOf(songs)));

    final reorder = target.reordered.single;
    expect(trackIdsOf(reorder.tracks), idsOf(state.songs));
    expect(reorder.order, unorderedEquals([0, 1, 2, 3, 4, 5, 6, 7]));
    expect(reorder.order.first, 3);
    expect(reorder.at, 0);
  });

  test('- un-shuffling puts the queue back in its original order', () async {
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs[3], songs, album);

    await playback.setShuffle(enabled: true);
    await playback.setShuffle(enabled: false);

    final state = container.read(playbackProvider);
    expect(state.shuffleEnabled, isFalse);
    expect(idsOf(state.songs), idsOf(songs));
    expect(state.currentMediaIndex, 3);
    expect(trackIdsOf(target.reordered.last.tracks), idsOf(songs));
    expect(target.reordered.last.at, 3);
  });

  test('- the playing song survives a shuffle round trip', () async {
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs.first, songs, album);

    target.moveTo(2);
    await Future<void>.delayed(Duration.zero);

    await playback.setShuffle(enabled: true);
    expect(container.read(playbackProvider).songs.first.id, 'c');
    expect(container.read(playbackProvider).currentMediaIndex, 0);

    await playback.setShuffle(enabled: false);
    final state = container.read(playbackProvider);
    expect(idsOf(state.songs), idsOf(songs));
    expect(state.songs[state.currentMediaIndex!].id, 'c');
  });

  test('- songs queued while shuffled land at the end afterwards', () async {
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs.first, songs.take(3).toList(), album);

    await playback.setShuffle(enabled: true);
    await playback.addToQueue(songs[5]);
    await playback.setShuffle(enabled: false);

    expect(idsOf(container.read(playbackProvider).songs), [
      'a',
      'b',
      'c',
      'f',
    ]);
  });

  test('- a new queue starts shuffled while shuffle is on', () async {
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs.first, songs, album);
    await playback.setShuffle(enabled: true);

    await playback.play(songs[6], songs, album);

    final state = container.read(playbackProvider);
    expect(state.currentMediaIndex, 0);
    expect(state.songs.first.id, 'g');
    expect(idsOf(state.songs), unorderedEquals(idsOf(songs)));
    expect(trackIdsOf(target.loaded.last), idsOf(state.songs));
  });

  test('- toggling shuffle on an empty queue asks for no reorder', () async {
    final playback = container.read(playbackProvider.notifier);

    await playback.setShuffle(enabled: true);

    expect(container.read(playbackProvider).shuffleEnabled, isTrue);
    expect(target.reordered, isEmpty);
  });
}
