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
    emit(playing: autoPlay, index: initialIndex);
  }

  void emit({
    required bool playing,
    int index = 0,
    Duration position = Duration.zero,
  }) {
    _state = TargetPlaybackState(
      status: playing ? PlaybackStatus.playing : PlaybackStatus.paused,
      position: position,
      currentIndex: index,
    );
    _controller.add(_state);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double level) async {}

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

  const album = LibraryItem(id: 'album', name: 'Album', kind: ItemKind.album);
  final songs = [
    for (final id in ['a', 'b'])
      LibraryItem(
        id: id,
        name: 'song $id',
        kind: ItemKind.song,
        duration: const Duration(minutes: 5),
      ),
  ];

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp(
      'playback_reporting_db',
    );
    await databaseFactory.setDatabasesPath(dbDir.path);
    registerFallbackValue(songs.first);
    registerFallbackValue(StreamTargetProfile.download(isAndroid: false));
    registerFallbackValue(
      const PlaybackReport(itemId: 'fallback', playSessionId: 'fallback'),
    );
    PlaybackNotifier.progressInterval = const Duration(milliseconds: 25);
  });

  tearDownAll(() {
    PlaybackNotifier.progressInterval = const Duration(seconds: 10);
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

  test('- a pause from the target silences periodic progress reports', () async {
    final notifier = container.read(playbackProvider.notifier);
    await notifier.play(songs.first, songs, album);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    verify(() => client.reportPlaybackStarted(any())).called(1);
    verify(
      () => client.reportPlaybackProgress(any()),
    ).called(greaterThanOrEqualTo(2));
    clearInteractions(client);

    target.emit(playing: false, position: const Duration(seconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(container.read(playbackProvider).status, PlaybackStatus.paused);
    final paused = verify(
      () => client.reportPlaybackProgress(captureAny()),
    ).captured;
    expect(paused, hasLength(1));
    expect((paused.single as PlaybackReport).isPaused, isTrue);
    verifyNever(() => client.reportPlaybackStopped(any()));

    target.emit(playing: true, position: const Duration(seconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(container.read(playbackProvider).status, PlaybackStatus.playing);
    final resumed = verify(
      () => client.reportPlaybackProgress(captureAny()),
    ).captured;
    expect(resumed.length, greaterThanOrEqualTo(2));
    expect((resumed.first as PlaybackReport).isPaused, isFalse);
  });
}
