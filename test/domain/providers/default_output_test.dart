import 'dart:async';
import 'dart:convert';
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
import 'package:jplayer/src/domain/playback/default_output.dart';
import 'package:jplayer/src/domain/playback/output_controller.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/cast_failure_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' hide equals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Target with Reconnectable implements PlaybackTarget {
  _Target({
    required this.id,
    required this.name,
    required this.kind,
    List<_Target>? family,
  }) : family = family ?? [] {
    this.family.add(this);
  }

  @override
  final String id;
  @override
  final String name;
  @override
  final PlaybackTargetKind kind;
  final List<_Target> family;
  bool failsOnLoad = false;

  final _controller = StreamController<TargetPlaybackState>.broadcast();
  final loads = <bool>[];
  int plays = 0;
  bool disposed = false;
  TargetPlaybackState _state = TargetPlaybackState.idle;

  void fail({bool takenOver = false}) {
    _state = TargetPlaybackState(
      status: PlaybackStatus.error,
      position: Duration.zero,
      takenOver: takenOver,
    );
    _controller.add(_state);
  }

  bool get _remote => kind != PlaybackTargetKind.local;

  Duration get _startTime => _remote
      ? const Duration(milliseconds: 1500)
      : const Duration(milliseconds: 300);

  Duration get _stopTime =>
      _remote ? const Duration(milliseconds: 400) : Duration.zero;

  @override
  PlaybackTarget reconnected() =>
      _Target(id: id, name: name, kind: kind, family: family);

  @override
  StreamTargetProfile get streamProfile => kind == PlaybackTargetKind.local
      ? StreamTargetProfile.localPlayer(isAndroid: false)
      : StreamTargetProfile.renderer(sinkMimeTypes: const {'audio/flac'});

  @override
  bool get supportsLocalFiles => kind == PlaybackTargetKind.local;

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
    loads.add(autoPlay);
    await Future<void>.delayed(_startTime);
    if (failsOnLoad) {
      fail();
      return;
    }
    _state = TargetPlaybackState(
      status: autoPlay ? PlaybackStatus.playing : PlaybackStatus.paused,
      position: initialPosition,
      currentIndex: initialIndex,
    );
    _controller.add(_state);
  }

  @override
  Future<void> play() async => plays++;

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() => Future<void>.delayed(_stopTime);

  @override
  Future<void> setVolume(double level) async {}

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Finder implements DefaultOutputFinder {
  _Finder(this.found);

  PlaybackTarget? found;
  final searches = <String>[];

  @override
  Future<PlaybackTarget?> find(DefaultOutput output) async {
    searches.add(output.name);
    await Future<void>.delayed(const Duration(seconds: 2));
    return found;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockMediaServerClient extends Mock implements MediaServerClient {}

final _livingRoom = DefaultOutput(
  kind: DefaultOutputKind.upnp,
  id: 'uuid:living',
  name: 'Living room',
  location: Uri.parse('http://10.0.0.5:1400/xml/device_description.xml'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late ProviderContainer container;
  late _Target local;
  late _Target speaker;
  late _Finder finder;
  late MediaServerClient client;
  var offline = false;

  const album = LibraryItem(id: 'album', name: 'Album', kind: ItemKind.album);
  final songs = [
    for (final id in ['a', 'b', 'c'])
      LibraryItem(
        id: id,
        name: 'song $id',
        kind: ItemKind.song,
        duration: const Duration(minutes: 4),
      ),
  ];

  setUpAll(() async {
    final dbDir = await Directory.systemTemp.createTemp('default_output_db');
    await databaseFactory.setDatabasesPath(dbDir.path);
    registerFallbackValue(songs.first);
    registerFallbackValue(StreamTargetProfile.download(isAndroid: false));
    registerFallbackValue(
      const PlaybackReport(itemId: 'fallback', playSessionId: 'fallback'),
    );
  });

  Future<void> start({
    DefaultOutput? output,
    bool withDefault = true,
    bool fallback = true,
  }) async {
    final chosen = withDefault ? (output ?? _livingRoom) : null;
    SharedPreferences.setMockInitialValues({
      'app_settings': jsonEncode({
        'default_output': chosen?.toJson() ?? <String, Object>{},
        'fallback_to_this_device': fallback,
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        localPlaybackTargetProvider.overrideWithValue(local),
        mediaServerClientProvider.overrideWith((_) => client),
        isOfflineProvider.overrideWith((_) => offline),
        appSettingsProvider.overrideWith((_) => AppSettingsNotifier(prefs)),
        defaultOutputFinderProvider.overrideWithValue(finder),
        playingElsewhereProvider.overrideWithValue(false),
      ],
    )..read(playbackProvider);
  }

  setUp(() async {
    deviceId = 'test-device';
    offline = false;
    final dir = await getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, 'downloads.db'));

    local = _Target(
      id: 'local',
      name: 'This device',
      kind: PlaybackTargetKind.local,
    );
    speaker = _Target(
      id: 'uuid:living',
      name: 'Living room',
      kind: PlaybackTargetKind.upnp,
    );
    finder = _Finder(speaker);
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
  });

  PlaybackNotifier playback() => container.read(playbackProvider.notifier);

  Future<void> until(bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (!done()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('timed out waiting for playback to settle');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  PlaybackStatus status() => container.read(playbackProvider).status;

  group('starting music', () {
    test('plays on the default speaker', () async {
      await start();

      await playback().play(songs.first, songs, album);

      expect(playback().target.id, 'uuid:living');
      expect(container.read(playbackTargetProvider).id, 'uuid:living');
      expect(speaker.loads, [true]);
      expect(local.loads, isEmpty);
    });

    test('stays here without a default', () async {
      await start(withDefault: false);

      await playback().play(songs.first, songs, album);

      expect(finder.searches, isEmpty);
      expect(local.loads, [true]);
    });

    test('plays here when the speaker is missing and fallback is on', () async {
      finder.found = null;
      await start();

      await playback().play(songs.first, songs, album);

      expect(local.loads, [true]);
      final failure = container.read(castFailureProvider);
      expect(failure?.notFound, isTrue);
      expect(failure?.message, contains('playing on this device'));
    });

    test(
      'stays paused when the speaker is missing and fallback is off',
      () async {
        finder.found = null;
        await start(fallback: false);

        await playback().play(songs.first, songs, album);

        expect(local.loads, [false]);
        expect(container.read(playbackProvider).status, PlaybackStatus.paused);
        expect(
          container.read(castFailureProvider)?.message,
          'Living room was not found on this network.',
        );
      },
    );

    test('a queue restored at startup stays here, paused', () async {
      await start();

      await playback().play(songs.first, songs, album, autoPlay: false);

      expect(finder.searches, isEmpty);
      expect(local.loads, [false]);
    });

    test('music started from the car stays here', () async {
      await start();

      await playback().playingHere(
        () => playback().play(songs.first, songs, album),
      );

      expect(finder.searches, isEmpty);
      expect(local.loads, [true]);
    });

    test('stays here while offline', () async {
      offline = true;
      await start();

      await playback().play(songs.first, songs, album);

      expect(finder.searches, isEmpty);
    });
  });

  group('picking an output', () {
    test('this device wins over the default until the app restarts', () async {
      await start();
      await container.read(outputControllerProvider).chooseHere();

      await playback().play(songs.first, songs, album);

      expect(finder.searches, isEmpty);
      expect(local.loads, [true]);
    });

    test('changing the default brings it back', () async {
      await start();
      await container.read(outputControllerProvider).chooseHere();

      container
          .read(appSettingsProvider.notifier)
          .setMap(
            AppSetting.defaultOutput,
            DefaultOutput(
              kind: DefaultOutputKind.upnp,
              id: 'uuid:kitchen',
              name: 'Kitchen',
              location: Uri.parse('http://10.0.0.6:1400/xml/desc.xml'),
            ).toJson(),
          );
      await playback().play(songs.first, songs, album);

      expect(finder.searches, ['Kitchen']);
    });

    test('a dropped speaker does not count as a pick', () async {
      await start();
      await playback().play(songs.first, songs, album);
      speaker.fail();
      await until(() => playback().target.id == 'local');
      expect(local.state.status, isNot(PlaybackStatus.playing));

      final again = _Target(
        id: 'uuid:living',
        name: 'Living room',
        kind: PlaybackTargetKind.upnp,
      );
      finder.found = again;
      await playback().play(songs[1], songs, album);

      expect(playback().target.id, 'uuid:living');
      expect(again.loads, [true]);
    });
  });

  group('pressing play on a paused queue', () {
    test('moves it to the default speaker', () async {
      await start();
      await playback().play(songs[1], songs, album, autoPlay: false);

      await playback().resume(userAction: true);

      expect(playback().target.id, 'uuid:living');
      expect(speaker.loads, [true]);
      expect(container.read(playbackProvider).currentMediaIndex, 1);
    });

    test('a resume from the car or a media key stays here', () async {
      await start();
      await playback().play(songs[1], songs, album, autoPlay: false);

      await playback().resume();

      expect(finder.searches, isEmpty);
      expect(local.plays, 1);
    });
  });

  group('when the default speaker is missing', () {
    late List<String> asked;

    void answer(bool? playHere) {
      asked = [];
      container.read(missingDefaultPromptProvider).handler = (output) async {
        asked.add(output.name);
        await Future<void>.delayed(const Duration(seconds: 1));
        return playHere;
      };
    }

    test('playing here removes the missing default', () async {
      finder.found = null;
      await start();
      answer(true);

      await playback().play(songs.first, songs, album);

      expect(asked, ['Living room']);
      expect(local.loads, [true]);
      expect(container.read(castFailureProvider), isNull);
      expect(container.read(defaultOutputProvider), isNull);

      await playback().play(songs[1], songs, album);

      expect(finder.searches, ['Living room']);
      expect(asked, hasLength(1));
      expect(local.loads, [true, true]);
    });

    test('pausing keeps the queue here and looks again next time', () async {
      finder.found = null;
      await start();
      answer(false);

      await playback().play(songs.first, songs, album);

      expect(local.loads, [false]);
      expect(status(), PlaybackStatus.paused);
      expect(container.read(castFailureProvider), isNull);
      expect(container.read(defaultOutputProvider), _livingRoom);

      await playback().play(songs[1], songs, album);

      expect(finder.searches, hasLength(2));
      expect(asked, hasLength(2));
    });

    test('without a screen to ask on it follows the setting', () async {
      finder.found = null;
      await start();
      answer(null);

      await playback().play(songs.first, songs, album);

      expect(local.loads, [true]);
      expect(container.read(castFailureProvider)?.notFound, isTrue);
    });

    test('a speaker that fails after it was found does not ask', () async {
      speaker.failsOnLoad = true;
      await start();
      answer(false);

      await playback().play(songs.first, songs, album);
      await until(() => local.state.status == PlaybackStatus.playing);

      expect(asked, isEmpty);
    });

    test('a speaker picked by hand never asks', () async {
      await start(withDefault: false);
      answer(false);
      final kitchen = _Target(
        id: 'uuid:kitchen',
        name: 'Kitchen',
        kind: PlaybackTargetKind.upnp,
      )..failsOnLoad = true;
      await playback().play(songs.first, songs, album);

      await container.read(outputControllerProvider).choose(kitchen);
      await until(() => playback().target.id == 'local');
      await playback().switchTarget(local);

      expect(local.loads, [true, true]);

      expect(asked, isEmpty);
    });
  });

  group('when the speaker fails', () {
    test('a speaker that never started hands over playing', () async {
      speaker.failsOnLoad = true;
      await start();

      await playback().play(songs.first, songs, album);
      await until(() => local.state.status == PlaybackStatus.playing);

      expect(playback().target.id, 'local');
      expect(local.loads, [true]);
      expect(status(), PlaybackStatus.playing);
    });

    test('with fallback off it stays on the speaker, paused', () async {
      await start(fallback: false);
      await playback().play(songs.first, songs, album);

      speaker.fail();
      await until(() => status() == PlaybackStatus.paused);

      expect(playback().target.id, 'uuid:living');
      expect(local.loads, isEmpty);
      expect(container.read(playbackProvider).status, PlaybackStatus.paused);
      final failure = container.read(castFailureProvider);
      expect(failure?.switchedHere, isFalse);
      expect(failure?.message, isNot(contains('switched back')));
    });

    test('with fallback off the next play reconnects', () async {
      await start(fallback: false);
      await playback().play(songs.first, songs, album);
      speaker.fail(takenOver: true);
      await until(() => status() == PlaybackStatus.paused);

      await playback().resume(userAction: true);

      expect(speaker.disposed, isTrue);
      expect(speaker.family, hasLength(2));
      final fresh = speaker.family.last;
      expect(container.read(playbackTargetProvider), same(fresh));
      expect(fresh.loads, [true]);
    });

    test('with fallback off a failed start stays paused', () async {
      speaker.failsOnLoad = true;
      await start(fallback: false);

      await playback().play(songs.first, songs, album);
      await until(() => status() == PlaybackStatus.paused);

      expect(playback().target.id, 'uuid:living');
    });
  });
}
