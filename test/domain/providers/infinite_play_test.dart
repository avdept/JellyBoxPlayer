import 'dart:async';
import 'dart:io';
import 'dart:math';

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
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/infinite_play_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeTarget implements PlaybackTarget {
  final _controller = StreamController<TargetPlaybackState>.broadcast();
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

  void moveTo(int index, {bool playing = true}) {
    _state = TargetPlaybackState(
      status: playing ? PlaybackStatus.playing : PlaybackStatus.paused,
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
  }) async {}

  @override
  Future<void> insertAll(
    int index,
    List<TargetTrack> tracks, {
    bool playNext = false,
  }) async {
    for (var offset = 0; offset < tracks.length; offset++) {
      inserted.add((index + offset, tracks[offset]));
    }
  }

  @override
  Future<void> remove(int index) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

LibraryItem _song(String id) => LibraryItem(
  id: id,
  name: 'song $id',
  kind: ItemKind.song,
  duration: const Duration(minutes: 4),
);

List<String> _ids(List<LibraryItem> items) => [
  for (final item in items) item.id,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const album = LibraryItem(id: 'album', name: 'Album', kind: ItemKind.album);
  final songs = [
    for (final id in ['a', 'b', 'c', 'd', 'e']) _song(id),
  ];

  group('pickInfinitePlaySeeds', () {
    test('- takes the set, the tail of the queue and a spread of the rest', () {
      final queue = [for (var i = 0; i < 10; i++) _song('s$i')];
      final seeds = pickInfinitePlaySeeds(
        queue,
        set: album,
        random: Random(1),
      );
      expect(_ids(seeds).take(4), ['album', 's9', 's8', 's7']);
      expect(seeds, hasLength(6));
      expect(_ids(seeds).toSet(), hasLength(6));
      expect(
        _ids(seeds).skip(4),
        everyElement(isNot(isIn(['album', 's9', 's8', 's7']))),
      );
    });

    test('- skips ephemeral sets and radio streams', () {
      const mix = LibraryItem(
        id: 'instant-mix:x',
        name: 'Mix',
        kind: ItemKind.playlist,
      );
      final radio = _song('radio').copyWith(path: 'http://radio/stream');
      final seeds = pickInfinitePlaySeeds(
        [_song('a'), radio, _song('b')],
        set: mix,
        random: Random(1),
      );
      expect(_ids(seeds), ['b', 'a']);
    });
  });

  group('infinitePlayStart', () {
    final queue = [
      for (final id in ['a', 'b', 'x', 'y', 'c']) _song(id),
    ];

    test('- marks the first added song of a contiguous block', () {
      expect(infinitePlayStart(queue, {'x', 'y'}), 2);
      expect(infinitePlayStart(queue, {'x', 'y', 'gone'}), 2);
      expect(infinitePlayStart(queue, {'c'}), 4);
    });

    test('- hides the mark once added songs are scattered', () {
      expect(infinitePlayStart(queue, {'x', 'c'}), isNull);
      expect(infinitePlayStart(queue, {'a', 'y'}), isNull);
      expect(infinitePlayStart(queue, const {}), isNull);
      expect(infinitePlayStart(queue, {'gone'}), isNull);
    });
  });

  group('mergeInfinitePlayMixes', () {
    test(
      '- interleaves the mixes, drops duplicates and stops at the limit',
      () {
        final merged = mergeInfinitePlayMixes(
          [
            [_song('a'), _song('x'), _song('y')],
            [_song('m'), _song('x'), _song('n'), _song('o')],
            const [],
          ],
          exclude: {'a'},
          limit: 4,
        );
        expect(_ids(merged), ['m', 'x', 'y', 'n']);
      },
    );
  });

  group('infinite play', () {
    late ProviderContainer container;
    late _FakeTarget target;
    late _MockMediaServerClient client;

    setUpAll(() async {
      final dbDir = await Directory.systemTemp.createTemp('infinite_play_db');
      await databaseFactory.setDatabasesPath(dbDir.path);
      registerFallbackValue(songs.first);
      registerFallbackValue(StreamTargetProfile.download(isAndroid: false));
      registerFallbackValue(
        const PlaybackReport(itemId: 'fallback', playSessionId: 'fallback'),
      );
    });

    Future<void> build({List<Override> overrides = const []}) async {
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
      when(
        () => client.reportPlaybackProgress(any()),
      ).thenAnswer((_) async {});
      when(
        () => client.getInstantMix(any(), limit: any(named: 'limit')),
      ).thenAnswer(
        (invocation) async => [
          _song('${invocation.positionalArguments.first}-1'),
          _song('${invocation.positionalArguments.first}-2'),
          songs[1],
        ],
      );

      container = ProviderContainer(
        overrides: [
          playbackProvider.overrideWith(
            (ref) => PlaybackNotifier(
              ref,
              queueEditTimeout: const Duration(milliseconds: 50),
            ),
          ),
          infinitePlayProvider.overrideWith(
            (ref) => InfinitePlayNotifier(ref, random: Random(1)),
          ),
          localPlaybackTargetProvider.overrideWithValue(target),
          remoteRendererProvider.overrideWithValue(null),
          mediaServerClientProvider.overrideWith((_) => client),
          isOfflineProvider.overrideWithValue(false),
          ...overrides,
        ],
      )..listen(infinitePlayProvider, (_, _) {});
    }

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    tearDown(() async {
      await container.read(playbackProvider.notifier).clear();
      container.dispose();
    });

    test('- tops the queue up when the last songs come into reach', () async {
      await build();
      final playback = container.read(playbackProvider.notifier);
      await playback.play(songs.first, songs, album);
      await settle();
      verifyNever(
        () => client.getInstantMix(any(), limit: any(named: 'limit')),
      );

      target.moveTo(2);
      await settle();

      final seeds = verify(
        () => client.getInstantMix(captureAny(), limit: infinitePlaySeedLimit),
      ).captured.cast<String>();
      expect(seeds.take(4), ['album', 'e', 'd', 'c']);
      expect(seeds, hasLength(6));

      final queue = _ids(container.read(playbackProvider).songs);
      expect(queue.take(5), ['a', 'b', 'c', 'd', 'e']);
      expect(queue.skip(5), isNotEmpty);
      expect(queue.toSet(), hasLength(queue.length));
      expect(queue.skip(5).first, 'album-1');
      expect(container.read(infinitePlayProvider), queue.skip(5).toSet());
      expect(target.inserted, hasLength(queue.length - 5));
    });

    test('- stays quiet while far from the end', () async {
      await build();
      final playback = container.read(playbackProvider.notifier);
      await playback.play(songs.first, songs, album);
      target.moveTo(1);
      await settle();
      verifyNever(
        () => client.getInstantMix(any(), limit: any(named: 'limit')),
      );
    });

    test(
      '- does nothing while paused, offline, on repeat or switched off',
      () async {
        await build();
        final playback = container.read(playbackProvider.notifier);
        await playback.play(songs.first, songs, album, autoPlay: false);
        target.moveTo(4, playing: false);
        await settle();
        verifyNever(
          () => client.getInstantMix(any(), limit: any(named: 'limit')),
        );

        container
            .read(appSettingsProvider.notifier)
            .setValue(AppSetting.repeatMode, 'all');
        target.moveTo(4);
        await settle();
        verifyNever(
          () => client.getInstantMix(any(), limit: any(named: 'limit')),
        );
        container
            .read(appSettingsProvider.notifier)
            .setValue(AppSetting.repeatMode, 'off');

        container
            .read(appSettingsProvider.notifier)
            .setEnabled(AppSetting.infinitePlayback, value: false);
        target.moveTo(3);
        await settle();
        verifyNever(
          () => client.getInstantMix(any(), limit: any(named: 'limit')),
        );
        container
            .read(appSettingsProvider.notifier)
            .setEnabled(AppSetting.infinitePlayback, value: true);

        container
            .read(appSettingsProvider.notifier)
            .setEnabled(AppSetting.offlineModeToggle, value: true);
        container
            .read(appSettingsProvider.notifier)
            .setEnabled(AppSetting.manualOffline, value: true);
        target.moveTo(4);
        await settle();
        verifyNever(
          () => client.getInstantMix(any(), limit: any(named: 'limit')),
        );
      },
    );

    test('- gives up on a queue the server has nothing new for', () async {
      await build();
      when(
        () => client.getInstantMix(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => [songs[1], songs[2]]);
      final playback = container.read(playbackProvider.notifier);
      await playback.play(songs.first, songs, album);
      target.moveTo(3);
      await settle();
      target.moveTo(4);
      await settle();

      verify(
        () => client.getInstantMix(any(), limit: any(named: 'limit')),
      ).called(6);
      expect(_ids(container.read(playbackProvider).songs), _ids(songs));

      await playback.addToQueue(_song('z'));
      target.moveTo(5);
      await settle();
      verify(
        () => client.getInstantMix(any(), limit: any(named: 'limit')),
      ).called(6);
    });

    test('- forgets what it added once a new queue starts', () async {
      await build();
      final playback = container.read(playbackProvider.notifier);
      await playback.play(songs.first, songs, album);
      target.moveTo(4);
      await settle();
      expect(container.read(infinitePlayProvider), isNotEmpty);

      const other = LibraryItem(
        id: 'other',
        name: 'Other',
        kind: ItemKind.album,
      );
      final fresh = [
        for (final id in ['q', 'r', 's', 't', 'u']) _song(id),
      ];
      await playback.play(fresh.first, fresh, other);
      await settle();
      expect(container.read(infinitePlayProvider), isEmpty);
    });
  });
}
