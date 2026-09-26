import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/audio/quality_extras.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/now_playing_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/network_type_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeTarget implements PlaybackTarget, SwappableQueue {
  final _controller = StreamController<TargetPlaybackState>.broadcast();

  final loaded = <List<TargetTrack>>[];
  final replaced = <(int, TargetTrack)>[];

  @override
  Future<void> insert(int index, TargetTrack track, {bool playNext = false}) =>
      Future<void>.value();

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

  TargetPlaybackState _state = TargetPlaybackState.idle;

  @override
  TargetPlaybackState get state => _state;

  void moveTo(int index) {
    _state = TargetPlaybackState(
      status: PlaybackStatus.playing,
      position: Duration.zero,
      currentIndex: index,
    );
    _controller.add(_state);
  }

  @override
  Stream<TargetPlaybackState> get stateStream => _controller.stream;

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
  Future<void> replace(int index, TargetTrack track) async {
    replaced.add((index, track));
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SwitchableNetwork extends NetworkTypeNotifier {
  _SwitchableNetwork(NetworkType initial) : super(hasCellular: false) {
    state = initial;
  }

  void use(NetworkType type) => state = type;
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ProviderContainer container;
  late _FakeTarget target;
  late _SwitchableNetwork network;
  late MediaServerClient client;
  late List<int?> requestedCaps;
  void Function()? onResolve;
  String? gatedSong;
  Completer<void>? resolveGate;
  late Directory filesDir;

  const album = LibraryItem(id: 'album', name: 'Album', kind: ItemKind.album);
  final songs = [
    for (final id in ['a', 'b', 'c', 'd'])
      LibraryItem(
        id: id,
        name: 'song $id',
        kind: ItemKind.song,
        audioSources: const [
          AudioSourceInfo(
            container: 'flac',
            codec: 'flac',
            bitRate: 1000000,
            sampleRate: 44100,
          ),
        ],
      ),
  ];

  List<int?> bitRatesOf(Iterable<TargetTrack> tracks) => [
    for (final track in tracks) QualityExtras.heard(track.extras).bitRate,
  ];

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('stream_quality_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
    registerFallbackValue(songs.first);
    registerFallbackValue(StreamTargetProfile.download(isAndroid: false));
    registerFallbackValue(
      const PlaybackReport(itemId: 'fallback', playSessionId: 'fallback'),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_settings': jsonEncode({
        AppSetting.streamQualityWifi.key: StreamQuality.original.name,
        AppSetting.streamQualityCellular.key: StreamQuality.kbps128.name,
      }),
    });
    deviceId = 'test-device';
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));
    filesDir = await Directory.systemTemp.createTemp('stream_quality_files');

    PlaybackNotifier.requalifyDelay = Duration.zero;
    target = _FakeTarget();
    network = _SwitchableNetwork(NetworkType.wifi);
    requestedCaps = [];
    onResolve = null;
    gatedSong = null;
    resolveGate = null;
    client = _MockMediaServerClient();
    when(
      () => client.resolveStreamSource(
        any(),
        playSessionId: any(named: 'playSessionId'),
        target: any(named: 'target'),
      ),
    ).thenAnswer((invocation) async {
      final song = invocation.positionalArguments.single as LibraryItem;
      final profile =
          invocation.namedArguments[#target]! as StreamTargetProfile;
      final kbps = profile.maxBitRate;
      requestedCaps.add(kbps);
      onResolve?.call();
      if (song.id == gatedSong) await resolveGate?.future;
      return StreamSource(
        uri: Uri.parse(
          'http://server/audio/${song.id}?cap=${kbps ?? 0}'
          '&session=${invocation.namedArguments[#playSessionId]}',
        ),
        isHls: false,
        outputContainer: kbps == null ? 'flac' : 'm4a',
        mimeType: kbps == null ? 'audio/flac' : 'audio/mp4',
        requiresTranscode: kbps != null,
        delivered: AudioSourceInfo(
          codec: kbps == null ? 'flac' : 'aac',
          bitRate: kbps == null ? 900000 : kbps * 1000,
        ),
      );
    });
    when(() => client.reportPlaybackStarted(any())).thenAnswer((_) async {});
    when(() => client.reportPlaybackStopped(any())).thenAnswer((_) async {});
    when(() => client.reportPlaybackProgress(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        localPlaybackTargetProvider.overrideWithValue(target),
        mediaServerClientProvider.overrideWith((_) => client),
        isOfflineProvider.overrideWithValue(false),
        networkTypeProvider.overrideWith((_) => network),
      ],
    );
    await container.read(sharedPreferencesProvider.future);
  });

  tearDown(() async {
    await container.read(playbackProvider.notifier).clear();
    container.dispose();
    if (filesDir.existsSync()) await filesDir.delete(recursive: true);
  });

  Future<void> pumpUntil(bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!done() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('- streams at the cap of the network in use', () async {
    network.use(NetworkType.cellular);

    await container
        .read(playbackProvider.notifier)
        .play(songs.first, songs, album);

    expect(requestedCaps, everyElement(128));
    expect(bitRatesOf(target.loaded.single), everyElement(128000));
    final first = target.loaded.single.first.extras;
    expect(QualityExtras.streamed(first)?.codec, 'aac');
    expect(QualityExtras.original(first).codec, 'flac');
  });

  test('- leaves streams uncapped on Wi-Fi set to original', () async {
    await container
        .read(playbackProvider.notifier)
        .play(songs.first, songs, album);

    expect(requestedCaps, everyElement(isNull));
    expect(bitRatesOf(target.loaded.single), everyElement(900000));
  });

  test(
    '- re-resolves every queued stream but the playing one when the network '
    'changes',
    () async {
      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      expect(container.read(playbackProvider).currentMediaIndex, 0);

      network.use(NetworkType.cellular);
      await pumpUntil(() => target.replaced.length == 3);

      expect([for (final entry in target.replaced) entry.$1], [1, 2, 3]);
      expect(
        bitRatesOf([for (final entry in target.replaced) entry.$2]),
        everyElement(128000),
      );
    },
  );

  test(
    '- re-resolves queued streams when the active setting changes',
    () async {
      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);

      container
          .read(appSettingsProvider.notifier)
          .setValue(AppSetting.streamQualityWifi, StreamQuality.kbps192.name);
      await pumpUntil(() => target.replaced.length == 3);

      expect(
        bitRatesOf([for (final entry in target.replaced) entry.$2]),
        everyElement(192000),
      );
    },
  );

  test('- settles a flapping network into a single requalify pass', () async {
    PlaybackNotifier.requalifyDelay = const Duration(milliseconds: 100);
    await container
        .read(playbackProvider.notifier)
        .play(songs.first, songs, album);
    requestedCaps.clear();

    network
      ..use(NetworkType.cellular)
      ..use(NetworkType.wifi)
      ..use(NetworkType.cellular);
    await pumpUntil(() => target.replaced.length == 3);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(target.replaced, hasLength(3));
    expect(requestedCaps, [128, 128, 128]);
  });

  test('- stops a stale pass when the network changes again', () async {
    PlaybackNotifier.requalifyDelay = const Duration(hours: 1);
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs.first, songs, album);
    requestedCaps.clear();

    Future<void>? fresh;
    onResolve = () {
      onResolve = null;
      network.use(NetworkType.wifi);
      fresh = playback.requalifyStreams();
    };
    network.use(NetworkType.cellular);
    await playback.requalifyStreams();
    await fresh;

    expect(requestedCaps, [128, null, null, null]);
    expect(target.replaced, isEmpty);
  });

  test('- retries a pass whose queue changed underneath it', () async {
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs.first, songs, album);
    gatedSong = 'b';
    resolveGate = Completer<void>();

    network.use(NetworkType.cellular);
    await pumpUntil(() => requestedCaps.contains(128));
    await playback.addToQueue(songs.first.copyWith(id: 'e', name: 'song e'));
    expect(container.read(playbackProvider).songs, hasLength(5));

    gatedSong = null;
    resolveGate!.complete();
    await pumpUntil(() => target.replaced.length == 3);

    expect([for (final entry in target.replaced) entry.$1], [1, 2, 3]);
  });

  test('- keeps the play session across a requalify', () async {
    final sessions = <String, List<String>>{};
    when(
      () => client.reportPlaybackStarted(any()),
    ).thenAnswer((invocation) async {
      final report = invocation.positionalArguments.single as PlaybackReport;
      sessions.putIfAbsent(report.itemId, () => []).add(report.playSessionId);
    });
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs.first, songs, album);
    final before = target.loaded.single[1].uri.queryParameters['session'];

    network.use(NetworkType.cellular);
    await pumpUntil(() => target.replaced.length == 3);
    target.moveTo(1);
    await pumpUntil(() => sessions.containsKey('b'));

    final after = target.replaced.first.$2.uri.queryParameters['session'];
    expect(after, before);
    expect(sessions['b'], [before]);
  });

  test('- swaps upcoming tracks first and wraps to played ones', () async {
    await container
        .read(playbackProvider.notifier)
        .play(songs[2], songs, album);

    network.use(NetworkType.cellular);
    await pumpUntil(() => target.replaced.length == 3);

    expect([for (final entry in target.replaced) entry.$1], [3, 0, 1]);
  });

  test('- leaves a stream alone when nothing about it changed', () async {
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs.first, songs, album);

    await playback.requalifyStreams();

    expect(target.replaced, isEmpty);
  });

  test('- updates state once per pass, not once per swap', () async {
    await container
        .read(playbackProvider.notifier)
        .play(songs.first, songs, album);
    var updates = 0;
    container.listen(
      playbackProvider.select((state) => state.deliveredQualities),
      (_, _) => updates++,
    );

    network.use(NetworkType.cellular);
    await pumpUntil(() => target.replaced.length == 3);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(updates, 1);
  });

  test('- ignores a change to the setting of the other network', () async {
    await container
        .read(playbackProvider.notifier)
        .play(songs.first, songs, album);

    container
        .read(appSettingsProvider.notifier)
        .setValue(AppSetting.streamQualityCellular, StreamQuality.kbps64.name);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(target.replaced, isEmpty);
  });

  test('- shows the delivered quality in now playing, not the file', () async {
    network.use(NetworkType.cellular);

    await container
        .read(playbackProvider.notifier)
        .play(songs.first, songs, album);

    final playing = container.read(nowPlayingProvider)!;
    final heard = QualityExtras.heard(playing.extras);
    final original = QualityExtras.original(playing.extras);
    expect(heard.codec, 'aac');
    expect(heard.bitRate, 128000);
    expect(original.codec, 'flac');
    expect(original.bitRate, 1000000);
    expect(original.sampleRate, 44100);
  });

  test('- updates queued now-playing entries after a requalify', () async {
    await container
        .read(playbackProvider.notifier)
        .play(songs.first, songs, album);

    network.use(NetworkType.cellular);
    await pumpUntil(() => target.replaced.length == 3);

    final queue = container.read(nowPlayingQueueProvider);
    expect(QualityExtras.heard(queue.first.extras).bitRate, 900000);
    expect(
      [
        for (final item in queue.skip(1))
          QualityExtras.heard(item.extras).bitRate,
      ],
      everyElement(128000),
    );
  });

  test('- falls back to the file quality once the queue is cleared', () async {
    network.use(NetworkType.cellular);
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs.first, songs, album);
    expect(container.read(playbackProvider).deliveredQualities, isNotEmpty);

    await playback.clear();

    expect(container.read(playbackProvider).deliveredQualities, isEmpty);
    final item = mediaItemFor(songs.first);
    expect(QualityExtras.heard(item.extras).codec, 'flac');
  });

  test('- reports the quality a cached file was fetched at', () async {
    final file = File(join(filesDir.path, 'b.m4a'))
      ..writeAsBytesSync(List.filled(16, 0));
    await container
        .read(queueCacheDatabaseProvider)
        .insert(
          songs[1],
          file: file,
          quality: const AudioSourceInfo(codec: 'aac', bitRate: 128000),
        );

    await container
        .read(playbackProvider.notifier)
        .play(songs.first, songs, album);

    final cached = target.loaded.single[1];
    expect(cached.isLocalFile, isTrue);
    expect(QualityExtras.heard(cached.extras).codec, 'aac');
    expect(QualityExtras.heard(cached.extras).bitRate, 128000);
    expect(QualityExtras.original(cached.extras).codec, 'flac');
  });
}
