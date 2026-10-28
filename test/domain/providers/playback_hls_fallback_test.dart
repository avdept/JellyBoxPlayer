import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/main.dart';
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
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/network_type_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeTarget
    implements PlaybackTarget, SwappableQueue, LoadFailureReporting {
  final _controller = StreamController<TargetPlaybackState>.broadcast();
  final failures = StreamController<TrackLoadFailure>.broadcast();

  final loaded = <List<TargetTrack>>[];
  final replaced = <(int, TargetTrack)>[];

  @override
  Stream<TrackLoadFailure> get loadFailures => failures.stream;

  @override
  bool get holdsCurrentTrack => true;

  @override
  PlaybackTargetKind get kind => PlaybackTargetKind.local;

  @override
  String get id => 'local';

  @override
  String get name => 'This device';

  @override
  StreamTargetProfile get streamProfile =>
      StreamTargetProfile.localPlayer(isAndroid: false, isDarwin: true);

  @override
  bool get supportsLocalFiles => true;

  @override
  TargetPlaybackState get state => TargetPlaybackState.idle;

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
  Future<void> dispose() async {
    await failures.close();
    await _controller.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WifiNetwork extends NetworkTypeNotifier {
  _WifiNetwork() : super(hasCellular: false) {
    state = NetworkType.wifi;
  }
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ProviderContainer container;
  late _FakeTarget target;
  late MediaServerClient client;
  late List<(String, bool)> resolves;

  const album = LibraryItem(id: 'album', name: 'Album', kind: ItemKind.album);
  final songs = [
    for (final id in ['a', 'b', 'c'])
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

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('hls_fallback_db');
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
        AppSetting.streamQualityWifi.key: StreamQuality.kbps128.name,
      }),
    });
    deviceId = 'test-device';
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));

    PlaybackNotifier.requalifyDelay = Duration.zero;
    target = _FakeTarget();
    resolves = [];
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
      resolves.add((song.id, profile.supportsHls));
      final hls = profile.supportsHls;
      final location = Uri.parse(
        hls ? 'audio/${song.id}/main.m3u8' : 'audio/${song.id}/universal',
      );
      return StreamSource(
        uri: Uri.parse('http://server/').resolveUri(location),
        location: location,
        isHls: hls,
        outputContainer: hls ? 'ts' : 'aac',
        mimeType: hls ? 'application/vnd.apple.mpegurl' : 'audio/aac',
        requiresTranscode: true,
        delivered: const AudioSourceInfo(codec: 'aac', bitRate: 128000),
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
        networkTypeProvider.overrideWith((_) => _WifiNetwork()),
      ],
    );
    await container.read(sharedPreferencesProvider.future);
  });

  tearDown(() async {
    await container.read(playbackProvider.notifier).clear();
    container.dispose();
  });

  Future<void> pumpUntil(bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!done() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test(
    '- swaps a failing HLS stream for a progressive one',
    () async {
      await container
          .read(playbackProvider.notifier)
          .play(songs.first, songs, album);
      expect(target.loaded.single.every((track) => track.isHls), isTrue);

      target.failures.add((itemId: 'b', index: 1, attempt: 1));
      await pumpUntil(() => target.replaced.isNotEmpty);

      final (index, replacement) = target.replaced.single;
      expect(index, 1);
      expect(replacement.isHls, isFalse);
      expect(replacement.location?.path, 'audio/b/universal');
    },
  );

  test('- keeps a fallen-back song progressive on requalify', () async {
    final playback = container.read(playbackProvider.notifier);
    await playback.play(songs.first, songs, album);

    target.failures.add((itemId: 'b', index: 1, attempt: 1));
    await pumpUntil(() => target.replaced.isNotEmpty);
    resolves.clear();

    container
        .read(appSettingsProvider.notifier)
        .setValue(AppSetting.streamQualityWifi, StreamQuality.kbps192.name);
    await pumpUntil(
      () => resolves.where((entry) => entry.$1 != 'a').length >= 2,
    );

    expect(resolves, contains(('b', false)));
    expect(resolves, contains(('c', true)));
  });

  test('- falls back once per song and leaves retries alone', () async {
    await container
        .read(playbackProvider.notifier)
        .play(songs.first, songs, album);

    target.failures.add((itemId: 'b', index: 1, attempt: 1));
    await pumpUntil(() => target.replaced.isNotEmpty);
    target.failures.add((itemId: 'b', index: 1, attempt: 2));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(target.replaced, hasLength(1));
  });
}
