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
import 'package:jplayer/src/domain/playback/play_request.dart';
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
  final loads = <({int index, bool autoPlay})>[];
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
    loads.add((index: initialIndex, autoPlay: autoPlay));
    _state = TargetPlaybackState(
      status: autoPlay ? PlaybackStatus.playing : PlaybackStatus.paused,
      position: initialPosition,
      currentIndex: initialIndex,
    );
    _controller.add(_state);
  }

  @override
  Future<void> insert(
    int index,
    TargetTrack track, {
    bool playNext = false,
  }) async {}

  @override
  Future<void> remove(int index) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

class _Remote implements RemotePlayback {
  _Remote({required this.takes, required this.onPlay, required this.onEdit});

  final bool takes;
  final void Function(PlayRequest request) onPlay;
  final void Function(String edit) onEdit;

  String _ids(List<LibraryItem> songs) =>
      songs.map((song) => song.id).join(',');

  @override
  Future<bool> play(PlayRequest request) async {
    onPlay(request);
    return takes;
  }

  @override
  Future<bool> enqueue(
    List<LibraryItem> songs, {
    required bool playNext,
  }) async {
    onEdit('enqueue ${_ids(songs)}${playNext ? ' next' : ''}');
    return takes;
  }

  @override
  Future<bool> replaceUpcoming(
    List<LibraryItem> songs,
    LibraryItem album, {
    String? sourceId,
  }) async {
    onEdit('replace ${_ids(songs)} from $sourceId');
    return takes;
  }

  @override
  Future<bool> move(int from, int to) async {
    onEdit('move $from $to');
    return takes;
  }

  @override
  Future<bool> remove(int index) async {
    onEdit('remove $index');
    return takes;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late _FakeTarget target;
  late MediaServerClient client;
  late List<PlayRequest> elsewhere;
  late List<String> edits;

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
    final dbDir = await Directory.systemTemp.createTemp('playback_remote_db');
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
    elsewhere = [];
    edits = [];
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

  PlaybackNotifier playbackWith({required bool playsElsewhere}) {
    final container = ProviderContainer(
      overrides: [
        localPlaybackTargetProvider.overrideWithValue(target),
        mediaServerClientProvider.overrideWith((_) => client),
        isOfflineProvider.overrideWithValue(false),
      ],
    );
    addTearDown(() async {
      await container.read(playbackProvider.notifier).clear();
      container.dispose();
    });
    return container.read(playbackProvider.notifier)
      ..remote = _Remote(
        takes: playsElsewhere,
        onPlay: elsewhere.add,
        onEdit: edits.add,
      );
  }

  test('a play while another device renders goes there, not here', () async {
    final playback = playbackWith(playsElsewhere: true);

    await playback.play(songs[1], songs, album, sourceId: 'playlist-1');

    expect(target.loads, isEmpty);
    expect(playback.state.songs, isEmpty);
    expect(elsewhere.single.itemIds, ['a', 'b', 'c']);
    expect(elsewhere.single.index, 1);
    expect(elsewhere.single.album.id, 'album');
    expect(elsewhere.single.sourceId, 'playlist-1');
  });

  test('a play nobody else takes is played here', () async {
    final playback = playbackWith(playsElsewhere: false);

    await playback.play(songs[1], songs, album);

    expect(elsewhere, hasLength(1));
    expect(target.loads.single.index, 1);
    expect(target.loads.single.autoPlay, isTrue);
    expect(playback.state.status, PlaybackStatus.playing);
  });

  test('queue edits while another device renders go there', () async {
    final playback = playbackWith(playsElsewhere: true);

    expect(await playback.playNext(songs[0]), isTrue);
    expect(await playback.addAllToQueue(songs), isTrue);
    expect(
      await playback.replaceUpcoming(songs, album, sourceId: 'mix'),
      isTrue,
    );
    await playback.moveInQueue(2, 0);
    await playback.removeFromQueue(1);

    expect(edits, [
      'enqueue a next',
      'enqueue a,b,c',
      'replace a,b,c from mix',
      'move 2 0',
      'remove 1',
    ]);
    expect(target.loads, isEmpty);
    expect(playback.state.songs, isEmpty);
  });

  test('queue edits nobody else takes are applied here', () async {
    final playback = playbackWith(playsElsewhere: false);
    await playback.play(songs[1], songs, album);

    expect(await playback.addToQueue(songs[0]), isTrue);
    await playback.removeFromQueue(0);

    expect(edits, ['enqueue a', 'remove 0']);
    expect(playback.state.songs.map((song) => song.id), ['b', 'c', 'a']);
  });

  test('loading a queue paused never asks another device', () async {
    final playback = playbackWith(playsElsewhere: true);

    await playback.play(songs[1], songs, album, autoPlay: false);

    expect(elsewhere, isEmpty);
    expect(target.loads.single.autoPlay, isFalse);
  });

  test('resuming at a position never asks another device', () async {
    final playback = playbackWith(playsElsewhere: true);

    await playback.play(
      songs[1],
      songs,
      album,
      initialPosition: const Duration(seconds: 30),
    );

    expect(elsewhere, isEmpty);
    expect(target.loads.single.index, 1);
  });
}
