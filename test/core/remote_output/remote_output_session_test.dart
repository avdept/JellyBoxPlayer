import 'dart:async';

import 'package:audio_service/audio_service.dart' as audio;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/platform/volume_keys.dart';
import 'package:jplayer/src/core/remote_output/remote_output_session.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/system_volume_provider.dart';
import 'package:jplayer/src/domain/providers/volume_keys_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:optional_features/jellybox_cloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubPlayback extends StateNotifier<PlaybackState>
    implements PlaybackNotifier {
  _StubPlayback() : super(PlaybackState.initial());

  final calls = <String>[];

  PlaybackState get current => state;

  set current(PlaybackState next) => state = next;

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> next() async => calls.add('next');

  @override
  Future<void> prev() async => calls.add('prev');

  @override
  Future<void> seek(Duration position) async =>
      calls.add('seek ${position.inSeconds}');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubCloud extends StateNotifier<CloudState> implements CloudNotifier {
  _StubCloud() : super(const CloudState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTarget implements PlaybackTarget {
  _FakeTarget({required this.id, required this.kind});

  @override
  final String id;
  @override
  final PlaybackTargetKind kind;

  final applied = <double>[];

  @override
  Future<void> setVolume(double level) async => applied.add(level);

  @override
  Future<double?> currentVolume() async => applied.lastOrNull;

  @override
  String get name => 'Speaker';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeKeys implements HardwareVolumeKeys {
  @override
  Stream<VolumeKey> get presses => const Stream.empty();

  @override
  Future<void> setCapture(bool enabled) async {}
}

class _FakeImages extends ImageService {
  _FakeImages() : super(client: () => throw UnimplementedError());

  @override
  Uri? songArtUri(LibraryItem song, {LibraryItem? album, int? size}) =>
      Uri.parse('art://${song.id}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StubPlayback playback;
  late _FakeTarget speaker;
  late ProviderContainer container;
  late List<audio.AudioHandler?> installs;
  late RemoteOutputSession session;
  late DateTime clock;

  const song = LibraryItem(
    id: 'a',
    name: 'One',
    kind: ItemKind.song,
    albumArtist: 'Portishead',
    albumName: 'Dummy',
    duration: Duration(minutes: 3),
  );
  const album = LibraryItem(id: 'd', name: 'Dummy', kind: ItemKind.album);

  PlaybackState state(
    Duration position, {
    PlaybackStatus status = PlaybackStatus.playing,
  }) => PlaybackState(
    album: album,
    songs: [song],
    status: status,
    position: position,
    cacheProgress: Duration.zero,
    totalDuration: const Duration(minutes: 3),
    currentMediaIndex: 0,
  );

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    playback = _StubPlayback();
    speaker = _FakeTarget(id: 'uuid:kef', kind: PlaybackTargetKind.upnp);
    clock = DateTime(2026, 11, 17, 12);
    installs = [];
    container = ProviderContainer(
      overrides: [
        cloudProvider.overrideWith((_) => _StubCloud()),
        remoteRendererProvider.overrideWithValue(null),
        usesSystemVolumeProvider.overrideWithValue(true),
        appSettingsProvider.overrideWith((_) => AppSettingsNotifier(prefs)),
        localPlaybackTargetProvider.overrideWithValue(
          _FakeTarget(id: 'phone', kind: PlaybackTargetKind.local),
        ),
        playbackProvider.overrideWith((_) => playback),
        imageServiceProvider.overrideWithValue(_FakeImages()),
        hardwareVolumeKeysProvider.overrideWithValue(_FakeKeys()),
      ],
    );
    addTearDown(container.dispose);
    session = RemoteOutputSession(
      container,
      install: installs.add,
      now: () => clock,
    );
    await pump();
  });

  Future<void> castTo(PlaybackTarget target) async {
    container.read(playbackTargetProvider.notifier).select(target);
    await pump();
  }

  test(
    '- takes the media session while a speaker plays, then gives it back',
    () async {
      expect(installs, [null]);

      await castTo(speaker);
      expect(installs.last, same(session));

      container.read(playbackTargetProvider.notifier).useLocal();
      await pump();
      expect(installs.last, isNull);
    },
  );

  test('- shows the song the speaker is playing', () async {
    await castTo(speaker);
    playback.current = state(const Duration(seconds: 10));
    await pump();

    expect(session.mediaItem.value?.title, 'One');
    expect(session.mediaItem.value?.artUri, Uri.parse('art://a'));
    final reported = session.playbackState.value;
    expect(reported.playing, isTrue);
    expect(reported.processingState, audio.AudioProcessingState.ready);
    expect(reported.updatePosition, const Duration(seconds: 10));
  });

  test('- goes idle once the queue has stopped', () async {
    await castTo(speaker);
    playback.current = state(const Duration(seconds: 10));
    await pump();
    playback.current = state(Duration.zero, status: PlaybackStatus.stopped);
    await pump();

    expect(
      session.playbackState.value.processingState,
      audio.AudioProcessingState.idle,
    );
  });

  test(
    '- leaves the session alone while the position merely advances',
    () async {
      await castTo(speaker);
      playback.current = state(const Duration(seconds: 10));
      await pump();
      final states = <audio.PlaybackState>[];
      session.playbackState.listen(states.add);
      await pump();
      expect(states, hasLength(1));

      clock = clock.add(const Duration(seconds: 1));
      playback.current = state(const Duration(seconds: 11));
      await pump();
      expect(states, hasLength(1));

      playback.current = state(const Duration(seconds: 40));
      await pump();
      expect(states, hasLength(2));
      expect(states.last.updatePosition, const Duration(seconds: 40));

      playback.current = state(
        const Duration(seconds: 40),
        status: PlaybackStatus.paused,
      );
      await pump();
      expect(states.last.playing, isFalse);
    },
  );

  test(
    '- reports the speaker volume and moves it from the lock screen',
    () async {
      await castTo(speaker);

      audio.RemoteAndroidPlaybackInfo info() =>
          session.androidPlaybackInfo.value as audio.RemoteAndroidPlaybackInfo;
      expect(info().maxVolume, 100);
      expect(info().volume, 10);

      await session.androidAdjustRemoteVolume(
        audio.AndroidVolumeDirection.raise,
      );
      await pump();
      expect(speaker.applied.last, 0.15);
      expect(info().volume, 15);

      await session.androidSetRemoteVolume(40);
      await pump();
      expect(speaker.applied.last, 0.4);
      expect(info().volume, 40);
    },
  );

  test('- sends the lock-screen controls to the speaker', () async {
    await castTo(speaker);
    playback.current = state(const Duration(seconds: 10));
    await pump();

    await session.play();
    await session.pause();
    await session.skipToNext();
    await session.skipToPrevious();
    await session.seek(const Duration(seconds: 5));
    await session.click();

    expect(playback.calls, [
      'resume',
      'pause',
      'next',
      'prev',
      'seek 5',
      'pause',
    ]);
  });
}
