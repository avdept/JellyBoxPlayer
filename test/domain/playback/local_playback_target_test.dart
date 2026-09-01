import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/playback/local_playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockAudioPlayer player;
  late StreamController<int?> indexes;
  late StreamController<Duration> positions;
  late StreamController<Duration?> durations;
  late StreamController<PlayerState> playerStates;
  late LocalPlaybackTarget target;

  setUpAll(() {
    registerFallbackValue(<AudioSource>[]);
    registerFallbackValue(Duration.zero);
  });

  void reportPlayer({
    required bool playing,
    required ProcessingState processingState,
    int? index = 0,
    Duration position = Duration.zero,
    Duration? duration,
  }) {
    final playerState = PlayerState(playing, processingState);
    when(() => player.playerState).thenReturn(playerState);
    when(() => player.playing).thenReturn(playing);
    when(() => player.currentIndex).thenReturn(index);
    when(() => player.position).thenReturn(position);
    when(() => player.duration).thenReturn(duration);
    playerStates.add(playerState);
  }

  setUp(() {
    player = MockAudioPlayer();
    indexes = StreamController<int?>.broadcast();
    positions = StreamController<Duration>.broadcast();
    durations = StreamController<Duration?>.broadcast();
    playerStates = StreamController<PlayerState>.broadcast();

    when(() => player.currentIndexStream).thenAnswer((_) => indexes.stream);
    when(() => player.positionStream).thenAnswer((_) => positions.stream);
    when(() => player.durationStream).thenAnswer((_) => durations.stream);
    when(() => player.playerStateStream).thenAnswer((_) => playerStates.stream);
    when(
      () => player.setAudioSources(
        any(),
        initialIndex: any(named: 'initialIndex'),
        initialPosition: any(named: 'initialPosition'),
        preload: any(named: 'preload'),
      ),
    ).thenAnswer((_) async => null);
    when(player.play).thenAnswer((_) async {});
    when(player.stop).thenAnswer((_) async {});
    when(() => player.seek(any(), index: any(named: 'index')))
        .thenAnswer((_) async {});
    when(() => player.setVolume(any())).thenAnswer((_) async {});
    reportPlayer(playing: false, processingState: ProcessingState.idle);

    target = LocalPlaybackTarget(player);
  });

  tearDown(() async {
    await target.dispose();
    await indexes.close();
    await positions.close();
    await durations.close();
    await playerStates.close();
  });

  TargetTrack trackWith({bool isHls = false}) => TargetTrack(
    itemId: 'song-1',
    uri: Uri.parse('http://jelly.local:8096/Audio/song-1/universal'),
    mimeType: 'audio/flac',
    isHls: isHls,
    title: 'Roads',
    duration: const Duration(minutes: 5),
    artist: 'Portishead',
    album: 'Dummy',
    extras: const {'codec': 'flac'},
  );

  group('identity', () {
    test('- streams for a local player and can play downloaded files', () {
      expect(target.id, 'local');
      expect(target.kind, PlaybackTargetKind.local);
      expect(target.supportsLocalFiles, isTrue);
      expect(target.streamProfile.supportsHls, isTrue);
    });
  });

  group('state mapping', () {
    test('- reports playing whatever the processing state says', () async {
      final states = target.stateStream.take(1).toList();
      reportPlayer(
        playing: true,
        processingState: ProcessingState.buffering,
        position: const Duration(seconds: 3),
        duration: const Duration(minutes: 4),
      );

      final state = (await states).single;
      expect(state.status, PlaybackStatus.playing);
      expect(state.position, const Duration(seconds: 3));
      expect(state.duration, const Duration(minutes: 4));
      expect(state.completed, isFalse);
    });

    test('- maps a ready but idle player to paused', () async {
      final states = target.stateStream.take(1).toList();
      reportPlayer(playing: false, processingState: ProcessingState.ready);

      expect((await states).single.status, PlaybackStatus.paused);
    });

    test('- maps loading and buffering to buffering', () async {
      final states = target.stateStream.take(2).toList();
      reportPlayer(playing: false, processingState: ProcessingState.loading);
      reportPlayer(playing: false, processingState: ProcessingState.buffering);

      expect(
        (await states).map((state) => state.status),
        everyElement(PlaybackStatus.buffering),
      );
    });

    test('- flags a completed queue', () async {
      final states = target.stateStream.take(1).toList();
      reportPlayer(
        playing: false,
        processingState: ProcessingState.completed,
        index: null,
      );

      final state = (await states).single;
      expect(state.completed, isTrue);
      expect(state.status, PlaybackStatus.stopped);
      expect(state.currentIndex, isNull);
    });

    test('- emits on a bare position tick as well', () async {
      final states = target.stateStream.take(1).toList();
      when(() => player.position).thenReturn(const Duration(seconds: 9));
      positions.add(const Duration(seconds: 9));

      expect((await states).single.position, const Duration(seconds: 9));
    });

    test('- keeps the last emitted state readable synchronously', () async {
      reportPlayer(playing: true, processingState: ProcessingState.ready);
      await Future<void>.delayed(Duration.zero);

      expect(target.state.status, PlaybackStatus.playing);
    });
  });

  group('load', () {
    test('- builds a progressive source with precise darwin timing', () async {
      await target.load(
        [trackWith()],
        initialIndex: 0,
        initialPosition: const Duration(seconds: 12),
        autoPlay: true,
      );

      final sources =
          verify(
                () => player.setAudioSources(
                  captureAny(),
                  initialIndex: 0,
                  initialPosition: const Duration(seconds: 12),
                  preload: true,
                ),
              ).captured.single
              as List<AudioSource>;

      expect(sources.single, isA<ProgressiveAudioSource>());
      verify(player.play).called(1);
    });

    test('- builds an HLS source for an HLS stream', () async {
      await target.load(
        [trackWith(isHls: true)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: false,
      );

      final sources =
          verify(
                () => player.setAudioSources(
                  captureAny(),
                  initialIndex: any(named: 'initialIndex'),
                  initialPosition: any(named: 'initialPosition'),
                  preload: any(named: 'preload'),
                ),
              ).captured.single
              as List<AudioSource>;

      expect(sources.single, isA<HlsAudioSource>());
      verifyNever(player.play);
    });

    test('- stops and retries once when the first load throws', () async {
      var attempts = 0;
      when(
        () => player.setAudioSources(
          any(),
          initialIndex: any(named: 'initialIndex'),
          initialPosition: any(named: 'initialPosition'),
          preload: any(named: 'preload'),
        ),
      ).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) throw Exception('load failed');
        return null;
      });

      await target.load(
        [trackWith()],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: false,
      );

      expect(attempts, 2);
      verify(player.stop).called(1);
    });
  });

  group('transport', () {
    test('- skipTo restarts the target index from zero', () async {
      await target.skipTo(3);

      verify(() => player.seek(Duration.zero, index: 3)).called(1);
    });

    test('- forwards volume changes', () async {
      await target.setVolume(0.4);

      verify(() => player.setVolume(0.4)).called(1);
    });
  });
}
