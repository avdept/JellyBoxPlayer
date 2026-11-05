import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeTarget implements PlaybackTarget {
  final _controller = StreamController<TargetPlaybackState>.broadcast();
  List<TargetTrack> loaded = const [];
  int stops = 0;
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
    loaded = tracks;
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
  Future<void> stop() async => stops++;

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
  late Directory filesDir;
  late ProviderContainer container;

  const album = LibraryItem(id: 'album', name: 'Album', kind: ItemKind.album);
  final songs = [
    for (final id in ['a', 'b', 'c'])
      LibraryItem(
        id: id,
        name: 'song $id',
        kind: ItemKind.song,
        albumId: 'album',
        duration: const Duration(minutes: 5),
      ),
  ];

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('manual_offline_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
    registerFallbackValue(songs.first);
    registerFallbackValue(StreamTargetProfile.download(isAndroid: false));
    registerFallbackValue(
      const PlaybackReport(itemId: 'fallback', playSessionId: 'fallback'),
    );
  });

  setUp(() async {
    deviceId = 'test-device';
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
    filesDir = await Directory.systemTemp.createTemp('manual_offline_files');
    DownloadPaths.root = filesDir.path;

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

  tearDown(() async {
    await container.read(playbackProvider.notifier).clear();
    container.dispose();
    DownloadPaths.root = null;
    if (filesDir.existsSync()) await filesDir.delete(recursive: true);
  });

  Future<PlaybackNotifier> playbackWith({required bool manualOffline}) async {
    SharedPreferences.setMockInitialValues({
      'app_settings': jsonEncode({
        AppSetting.offlineModeToggle.key: true,
        AppSetting.manualOffline.key: manualOffline,
      }),
    });
    container = ProviderContainer(
      overrides: [
        localPlaybackTargetProvider.overrideWithValue(target),
        mediaServerClientProvider.overrideWith((_) => client),
        isOfflineProvider.overrideWithValue(false),
      ],
    );
    await container.read(sharedPreferencesProvider.future);
    final file = File(join(filesDir.path, 'album', 'a.flac'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    await container
        .read(downloadDatabaseProvider)
        .insertDownloadedSong(songs.first, file: file);
    return container.read(playbackProvider.notifier);
  }

  void goOffline() => container
      .read(appSettingsProvider.notifier)
      .setEnabled(AppSetting.manualOffline, value: true);

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('plays only downloaded songs while manually offline', () async {
    final playback = await playbackWith(manualOffline: true);

    await playback.play(songs[1], songs, album);

    expect(playback.state.songs.map((song) => song.id), ['a']);
    expect(target.loaded.single.isLocalFile, isTrue);
    verifyNever(
      () => client.resolveStreamSource(
        any(),
        playSessionId: any(named: 'playSessionId'),
        target: any(named: 'target'),
      ),
    );
  });

  test('drops queued streams and stops a streaming track', () async {
    final playback = await playbackWith(manualOffline: false);
    await playback.play(songs[1], songs, album);
    expect(playback.state.songs, hasLength(3));

    goOffline();
    await settle();

    expect(playback.state.songs.map((song) => song.id), ['a']);
    expect(target.stops, 1);
    expect(playback.state.status, PlaybackStatus.stopped);
  });

  test('keeps playing a downloaded track when going offline', () async {
    final playback = await playbackWith(manualOffline: false);
    await playback.play(songs[0], songs, album);

    goOffline();
    await settle();

    expect(playback.state.songs.map((song) => song.id), ['a']);
    expect(target.stops, 0);
    expect(playback.state.status, PlaybackStatus.playing);
  });
}
