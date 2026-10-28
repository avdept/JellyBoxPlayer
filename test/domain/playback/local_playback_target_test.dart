import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/queue_shuffle_order.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/playback/local_playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockAudioPlayer player;
  late StreamController<int?> indexes;
  late StreamController<Duration> positions;
  late StreamController<Duration?> durations;
  late StreamController<PlayerState> playerStates;
  late StreamController<PlayerException> errors;
  late StreamController<bool> online;
  late LocalPlaybackTarget target;

  setUpAll(() {
    registerFallbackValue(<AudioSource>[]);
    registerFallbackValue(AudioSource.uri(Uri.parse('http://jelly.local')));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(QueueShuffleOrder());
  });

  void reportPlayer({
    required bool playing,
    required ProcessingState processingState,
    int? index = 0,
    Duration position = Duration.zero,
    Duration? duration,
    Duration bufferedPosition = Duration.zero,
  }) {
    final playerState = PlayerState(playing, processingState);
    when(() => player.playerState).thenReturn(playerState);
    when(() => player.playing).thenReturn(playing);
    when(() => player.currentIndex).thenReturn(index);
    when(() => player.position).thenReturn(position);
    when(() => player.duration).thenReturn(duration);
    when(() => player.bufferedPosition).thenReturn(bufferedPosition);
    playerStates.add(playerState);
  }

  setUp(() {
    player = MockAudioPlayer();
    indexes = StreamController<int?>.broadcast();
    positions = StreamController<Duration>.broadcast();
    durations = StreamController<Duration?>.broadcast();
    playerStates = StreamController<PlayerState>.broadcast();
    errors = StreamController<PlayerException>.broadcast();
    online = StreamController<bool>.broadcast();

    when(() => player.bufferedPosition).thenReturn(Duration.zero);
    when(() => player.errorStream).thenAnswer((_) => errors.stream);
    when(() => player.sequence).thenReturn([
      AudioSource.uri(Uri.parse('http://jelly.local/a')),
      AudioSource.uri(Uri.parse('http://jelly.local/b')),
    ]);
    when(() => player.effectiveIndices).thenReturn([0, 1]);
    when(player.pause).thenAnswer((_) async {});
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
        shuffleOrder: any(named: 'shuffleOrder'),
      ),
    ).thenAnswer((_) async => null);
    when(player.play).thenAnswer((_) async {});
    when(player.stop).thenAnswer((_) async {});
    when(
      () => player.seek(any(), index: any(named: 'index')),
    ).thenAnswer((_) async {});
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
    await errors.close();
    await online.close();
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

  group('idle stop', () {
    const after = Duration(milliseconds: 30);
    const longer = Duration(milliseconds: 80);

    late LocalPlaybackTarget idle;

    setUp(() => idle = LocalPlaybackTarget(player, idleStopAfter: after));
    tearDown(() => idle.dispose());

    test('- releases the player after staying paused', () async {
      reportPlayer(playing: false, processingState: ProcessingState.ready);
      await Future<void>.delayed(longer);

      verify(player.stop).called(1);
    });

    test('- keeps a player that resumed before the timeout', () async {
      reportPlayer(playing: false, processingState: ProcessingState.ready);
      reportPlayer(playing: true, processingState: ProcessingState.ready);
      await Future<void>.delayed(longer);

      verifyNever(player.stop);
    });

    test(
      '- ignores a player with nothing loaded or a finished queue',
      () async {
        reportPlayer(playing: false, processingState: ProcessingState.idle);
        reportPlayer(
          playing: false,
          processingState: ProcessingState.completed,
        );
        await Future<void>.delayed(longer);

        verifyNever(player.stop);
      },
    );
  });

  test(
    '- a target without an idle timeout never stops a paused player',
    () async {
      reportPlayer(playing: false, processingState: ProcessingState.ready);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      verifyNever(player.stop);
    },
  );

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

    test('- maps a player that is still activating to buffering', () async {
      final states = target.stateStream.take(1).toList();
      reportPlayer(playing: true, processingState: ProcessingState.idle);

      expect((await states).single.status, PlaybackStatus.buffering);
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

  group('update rate', () {
    late List<TargetPlaybackState> states;
    late StreamSubscription<TargetPlaybackState> subscription;

    setUp(() {
      states = [];
      subscription = target.stateStream.listen(states.add);
    });
    tearDown(() => subscription.cancel());

    void tick(Duration position) {
      when(() => player.position).thenReturn(position);
      positions.add(position);
    }

    test('- coalesces position ticks while playing', () async {
      reportPlayer(playing: true, processingState: ProcessingState.ready);
      for (var ms = 20; ms <= 100; ms += 20) {
        tick(Duration(milliseconds: ms));
      }
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(1));

      await Future<void>.delayed(LocalPlaybackTarget.positionInterval);
      tick(const Duration(milliseconds: 300));
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(2));
      expect(states.last.position, const Duration(milliseconds: 300));
    });

    test('- passes every position while paused, such as a seek', () async {
      reportPlayer(playing: false, processingState: ProcessingState.ready);
      tick(const Duration(seconds: 30));
      tick(const Duration(seconds: 60));
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(3));
      expect(states.last.position, const Duration(seconds: 60));
    });

    test('- ignores a repeated current index', () async {
      indexes
        ..add(0)
        ..add(0)
        ..add(0)
        ..add(1);
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(2));
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
                  shuffleOrder: any(named: 'shuffleOrder'),
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
                  shuffleOrder: any(named: 'shuffleOrder'),
                ),
              ).captured.single
              as List<AudioSource>;

      expect(sources.single, isA<HlsAudioSource>());
      verifyNever(player.play);
    });

    group('when the stream cannot be loaded', () {
      const soon = Duration(milliseconds: 10);
      const later = Duration(milliseconds: 60);
      late int attempts;
      late int failures;

      setUp(() async {
        await target.dispose();
        attempts = 0;
        failures = 1;
        when(
          () => player.setAudioSources(
            any(),
            initialIndex: any(named: 'initialIndex'),
            initialPosition: any(named: 'initialPosition'),
            preload: any(named: 'preload'),
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).thenAnswer((_) async {
          attempts++;
          if (attempts <= failures) throw Exception('no network');
          return null;
        });
      });

      LocalPlaybackTarget targetThatRetries({
        bool isOnline = true,
        Duration offlineRetryEvery = const Duration(seconds: 30),
        int skipAfter = 10,
        Duration retryDelay = soon,
        Duration loadTimeout = LocalPlaybackTarget.defaultLoadTimeout,
        Duration stopTimeout = LocalPlaybackTarget.defaultStopTimeout,
      }) {
        final retrying = LocalPlaybackTarget(
          player,
          isOnline: () => isOnline,
          onlineChanges: () => online.stream,
          retryDelays: [retryDelay],
          offlineRetryEvery: offlineRetryEvery,
          skipAfter: skipAfter,
          loadTimeout: loadTimeout,
          stopTimeout: stopTimeout,
        );
        addTearDown(retrying.dispose);
        return retrying;
      }

      test('- keeps retrying a queue that was meant to play', () async {
        failures = 3;
        final retrying = targetThatRetries();

        await retrying.load(
          [trackWith()],
          initialIndex: 0,
          initialPosition: const Duration(seconds: 12),
          autoPlay: true,
        );

        expect(retrying.state.status, PlaybackStatus.buffering);
        expect(retrying.state.position, const Duration(seconds: 12));
        verifyNever(player.play);

        await Future<void>.delayed(later);

        expect(attempts, 4);
        expect(retrying.retryPending, isFalse);
        verify(player.play).called(1);
        verify(
          () => player.setAudioSources(
            any(),
            initialIndex: 0,
            initialPosition: const Duration(seconds: 12),
            preload: true,
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).called(4);
      });

      test('- waits for the connection instead of polling offline', () async {
        final retrying = targetThatRetries(isOnline: false);

        await retrying.load(
          [trackWith()],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await Future<void>.delayed(later);

        expect(attempts, 1);

        online.add(true);
        await Future<void>.delayed(soon);

        expect(attempts, 2);
        verify(player.play).called(1);
      });

      test('- leaves a paused queue to reload on play', () async {
        when(() => player.sequence).thenReturn([
          for (final name in ['a', 'b', 'c'])
            AudioSource.uri(Uri.parse('http://jelly.local/$name')),
        ]);
        final retrying = targetThatRetries();

        await retrying.load(
          [trackWith()],
          initialIndex: 2,
          initialPosition: const Duration(seconds: 40),
          autoPlay: false,
        );
        await Future<void>.delayed(later);

        expect(attempts, 1);
        expect(retrying.state.status, PlaybackStatus.paused);
        expect(retrying.state.currentIndex, 2);
        verifyNever(player.play);

        await retrying.play();

        expect(attempts, 2);
        verify(
          () => player.setAudioSources(
            any(),
            initialIndex: 2,
            initialPosition: const Duration(seconds: 40),
            preload: true,
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).called(2);
        verify(player.play).called(1);
      });

      test('- a play that bypassed the target still gets retried', () async {
        failures = 2;
        final retrying = targetThatRetries();
        await retrying.load(
          [trackWith()],
          initialIndex: 1,
          initialPosition: const Duration(seconds: 5),
          autoPlay: false,
        );
        expect(retrying.state.status, PlaybackStatus.paused);

        reportPlayer(playing: true, processingState: ProcessingState.idle);
        errors.add(PlayerException(1, 'Source error', 1));
        await Future<void>.delayed(Duration.zero);

        expect(retrying.state.status, PlaybackStatus.buffering);

        await Future<void>.delayed(later);

        expect(attempts, 3);
        verify(
          () => player.setAudioSources(
            any(),
            initialIndex: 1,
            initialPosition: const Duration(seconds: 5),
            preload: true,
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).called(3);
        verify(player.play).called(1);
      });

      test('- skips a track that keeps failing while online', () async {
        when(
          () => player.setAudioSources(
            any(),
            initialIndex: any(named: 'initialIndex'),
            initialPosition: any(named: 'initialPosition'),
            preload: any(named: 'preload'),
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).thenAnswer((invocation) async {
          attempts++;
          if (invocation.namedArguments[#initialIndex] == 0) {
            throw Exception('gone from the server');
          }
          return null;
        });
        final retrying = targetThatRetries(skipAfter: 2);

        await retrying.load(
          [trackWith(), trackWith()],
          initialIndex: 0,
          initialPosition: const Duration(seconds: 12),
          autoPlay: true,
        );
        await Future<void>.delayed(later);

        expect(retrying.state.status, isNot(PlaybackStatus.error));
        expect(retrying.retryPending, isFalse);
        verify(
          () => player.setAudioSources(
            any(),
            initialIndex: 1,
            initialPosition: Duration.zero,
            preload: true,
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).called(1);
        verify(player.play).called(1);
      });

      test('- play presses do not restart the skip count', () async {
        failures = 10;
        final retrying = targetThatRetries(
          retryDelay: const Duration(seconds: 5),
          skipAfter: 2,
        );

        await retrying.load(
          [trackWith(), trackWith()],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        expect(attempts, 1);

        await retrying.play();
        expect(attempts, 2);
        await retrying.play();
        await Future<void>.delayed(soon);

        expect(retrying.state.currentIndex, 1);
        verify(
          () => player.setAudioSources(
            any(),
            initialIndex: 1,
            initialPosition: Duration.zero,
            preload: true,
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).called(1);
      });

      test('- reports which track failed to load', () async {
        when(() => player.sequence).thenReturn([
          AudioSource.uri(
            Uri.parse('http://127.0.0.1:1234/x/main.m3u8'),
            tag: const MediaItem(id: 'song-1', title: 'Roads'),
          ),
        ]);
        failures = 100;
        final retrying = targetThatRetries(
          retryDelay: const Duration(seconds: 5),
        );
        final reported = <TrackLoadFailure>[];
        retrying.loadFailures.listen(reported.add);

        await retrying.load(
          [trackWith(isHls: true)],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await Future<void>.delayed(soon);

        expect(reported, hasLength(1));
        expect(reported.single.itemId, 'song-1');
        expect(reported.single.index, 0);
      });

      test('- never skips while offline', () async {
        failures = 100;
        final retrying = targetThatRetries(
          isOnline: false,
          offlineRetryEvery: soon,
          skipAfter: 2,
        );

        await retrying.load(
          [trackWith(), trackWith()],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await Future<void>.delayed(later);

        expect(attempts, greaterThan(3));
        expect(retrying.state.currentIndex, 0);
        expect(retrying.state.status, PlaybackStatus.buffering);
        verifyNever(
          () => player.setAudioSources(
            any(),
            initialIndex: 1,
            initialPosition: any(named: 'initialPosition'),
            preload: any(named: 'preload'),
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        );
      });

      test('- gives up with an error when no track is left', () async {
        failures = 100;
        final retrying = targetThatRetries(skipAfter: 1);

        await retrying.load(
          [trackWith(), trackWith()],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await Future<void>.delayed(later);

        expect(retrying.state.status, PlaybackStatus.error);
        expect(retrying.retryPending, isFalse);
        final before = attempts;
        await Future<void>.delayed(later);
        expect(attempts, before);
        verifyNever(player.play);
      });

      test('- follows the pending track when the queue shifts', () async {
        final a = AudioSource.uri(Uri.parse('http://jelly.local/a'));
        final b = AudioSource.uri(Uri.parse('http://jelly.local/b'));
        final added = AudioSource.uri(Uri.parse('http://jelly.local/new'));
        when(() => player.sequence).thenReturn([a, b]);
        failures = 1;
        final retrying = targetThatRetries(
          retryDelay: const Duration(seconds: 5),
        );

        await retrying.load(
          [trackWith(), trackWith()],
          initialIndex: 1,
          initialPosition: const Duration(seconds: 20),
          autoPlay: true,
        );
        expect(retrying.state.currentIndex, 1);

        when(() => player.sequence).thenReturn([added, a, b]);
        when(() => player.effectiveIndices).thenReturn([0, 1, 2]);
        await retrying.play();

        verify(
          () => player.setAudioSources(
            any(),
            initialIndex: 2,
            initialPosition: const Duration(seconds: 20),
            preload: true,
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).called(1);
        expect(retrying.retryPending, isFalse);
      });

      test('- asks for a connection check when a load is deferred', () async {
        var checks = 0;
        final retrying = LocalPlaybackTarget(
          player,
          recheckConnection: () async => checks++,
          retryDelays: const [Duration(seconds: 5)],
        );
        addTearDown(retrying.dispose);

        await retrying.load(
          [trackWith()],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );

        expect(checks, 1);
        expect(retrying.holdsCurrentTrack, isFalse);
      });

      test('- a replaced pending track is retried at once', () async {
        final stale = AudioSource.uri(Uri.parse('http://home/a'));
        final fresh = AudioSource.uri(Uri.parse('http://tunnel/a'));
        when(() => player.sequence).thenReturn([stale]);
        when(() => player.removeAudioSourceAt(any())).thenAnswer((_) async {});
        when(
          () => player.insertAudioSource(any(), any()),
        ).thenAnswer((_) async {});
        failures = 1;
        final retrying = targetThatRetries(
          retryDelay: const Duration(seconds: 5),
          skipAfter: 1,
        );

        await retrying.load(
          [trackWith()],
          initialIndex: 0,
          initialPosition: const Duration(seconds: 42),
          autoPlay: true,
        );
        expect(attempts, 1);

        when(() => player.sequence).thenReturn([fresh]);
        await retrying.replace(0, trackWith());
        await Future<void>.delayed(soon);

        expect(attempts, 2);
        expect(retrying.retryPending, isFalse);
        verify(
          () => player.setAudioSources(
            [fresh],
            initialIndex: 0,
            initialPosition: const Duration(seconds: 42),
            preload: true,
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).called(1);
        verify(player.play).called(1);
      });

      test('- pausing calls the retries off', () async {
        failures = 10;
        final retrying = targetThatRetries(
          retryDelay: const Duration(seconds: 5),
        );

        await retrying.load(
          [trackWith()],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await retrying.pause();
        await Future<void>.delayed(later);

        expect(attempts, 1);
        expect(retrying.state.status, PlaybackStatus.paused);
      });

      test('- stops a load that never answers and retries it', () async {
        final stuck = Completer<Duration?>();
        var calls = 0;
        when(
          () => player.setAudioSources(
            any(),
            initialIndex: any(named: 'initialIndex'),
            initialPosition: any(named: 'initialPosition'),
            preload: any(named: 'preload'),
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).thenAnswer((_) {
          calls++;
          return calls == 1 ? stuck.future : Future.value();
        });
        final retrying = targetThatRetries(loadTimeout: soon);

        await retrying.load(
          [trackWith()],
          initialIndex: 0,
          initialPosition: const Duration(seconds: 7),
          autoPlay: true,
        );

        expect(retrying.state.status, PlaybackStatus.buffering);
        expect(retrying.retryPending, isTrue);
        verify(player.stop).called(1);
        verifyNever(player.play);

        await Future<void>.delayed(later);

        expect(calls, 2);
        expect(retrying.retryPending, isFalse);
        verify(
          () => player.setAudioSources(
            any(),
            initialIndex: 0,
            initialPosition: const Duration(seconds: 7),
            preload: true,
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).called(2);
        verify(player.play).called(1);
      });

      test('- a player that will not stop does not block the retry', () async {
        when(player.stop).thenAnswer((_) => Completer<void>().future);
        final retrying = targetThatRetries(stopTimeout: soon);

        await retrying.load(
          [trackWith()],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );

        expect(retrying.retryPending, isTrue);

        await Future<void>.delayed(later);

        expect(attempts, 2);
        expect(retrying.retryPending, isFalse);
        verify(player.play).called(1);
      });

      test('- next while a load is pending moves the retry along', () async {
        failures = 10;
        final retrying = targetThatRetries(
          retryDelay: const Duration(seconds: 5),
        );
        await retrying.load(
          [trackWith(), trackWith()],
          initialIndex: 0,
          initialPosition: const Duration(seconds: 30),
          autoPlay: true,
        );
        expect(attempts, 1);

        await retrying.seekToNext();
        expect(retrying.state.currentIndex, 1);
        expect(retrying.state.position, Duration.zero);
        expect(retrying.state.status, PlaybackStatus.buffering);
        await Future<void>.delayed(soon);

        expect(attempts, 2);
        verify(
          () => player.setAudioSources(
            any(),
            initialIndex: 1,
            initialPosition: Duration.zero,
            preload: true,
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).called(1);
        verifyNever(() => player.seek(any(), index: any(named: 'index')));
      });

      test('- previous while pending restarts or steps back', () async {
        failures = 10;
        final retrying = targetThatRetries(
          retryDelay: const Duration(seconds: 5),
        );
        await retrying.load(
          [trackWith(), trackWith()],
          initialIndex: 1,
          initialPosition: const Duration(seconds: 40),
          autoPlay: true,
        );

        await retrying.seekToPrevious();
        expect(retrying.state.currentIndex, 1);
        expect(retrying.state.position, Duration.zero);

        await retrying.seekToPrevious();
        expect(retrying.state.currentIndex, 0);
        await Future<void>.delayed(soon);

        verify(
          () => player.setAudioSources(
            any(),
            initialIndex: 0,
            initialPosition: Duration.zero,
            preload: true,
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).called(1);
      });

      test(
        '- a queue tap while paused and pending sets up the next play',
        () async {
          final retrying = targetThatRetries(
            retryDelay: const Duration(seconds: 5),
          );
          await retrying.load(
            [trackWith(), trackWith()],
            initialIndex: 0,
            initialPosition: Duration.zero,
            autoPlay: false,
          );
          expect(attempts, 1);

          await retrying.skipTo(1);
          await Future<void>.delayed(soon);
          expect(attempts, 1);
          expect(retrying.state.currentIndex, 1);
          expect(retrying.state.status, PlaybackStatus.paused);

          await retrying.play();

          expect(attempts, 2);
          verify(
            () => player.setAudioSources(
              any(),
              initialIndex: 1,
              initialPosition: Duration.zero,
              preload: true,
              shuffleOrder: any(named: 'shuffleOrder'),
            ),
          ).called(1);
          verify(player.play).called(1);
        },
      );

      test('- a stale load cannot undo a newer one', () async {
        final stuck = Completer<Duration?>();
        var calls = 0;
        when(
          () => player.setAudioSources(
            any(),
            initialIndex: any(named: 'initialIndex'),
            initialPosition: any(named: 'initialPosition'),
            preload: any(named: 'preload'),
            shuffleOrder: any(named: 'shuffleOrder'),
          ),
        ).thenAnswer((_) {
          calls++;
          return calls == 1 ? stuck.future : Future.value();
        });
        final retrying = targetThatRetries(loadTimeout: later);

        final first = retrying.load(
          [trackWith()],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await retrying.load(
          [trackWith()],
          initialIndex: 1,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await first;
        await Future<void>.delayed(later + soon);

        expect(calls, 2);
        expect(retrying.retryPending, isFalse);
        verifyNever(player.stop);
        verify(player.play).called(1);
      });

      test(
        '- a stream that drops while playing resumes where it was',
        () async {
          failures = 0;
          final retrying = targetThatRetries();
          reportPlayer(
            playing: true,
            processingState: ProcessingState.ready,
            index: 1,
            position: const Duration(seconds: 30),
          );
          await Future<void>.delayed(Duration.zero);

          errors.add(PlayerException(1, 'Source error', 1));
          await Future<void>.delayed(Duration.zero);

          expect(retrying.state.status, PlaybackStatus.buffering);
          verify(player.stop).called(1);

          await Future<void>.delayed(later);

          verify(
            () => player.setAudioSources(
              any(),
              initialIndex: 1,
              initialPosition: const Duration(seconds: 30),
              preload: true,
              shuffleOrder: any(named: 'shuffleOrder'),
            ),
          ).called(1);
          verify(player.play).called(1);
        },
      );
    });
  });

  group('play', () {
    test('- clears a playing flag that has nothing loaded behind it', () async {
      reportPlayer(playing: true, processingState: ProcessingState.idle);

      await target.play();

      verifyInOrder([player.pause, player.play]);
    });

    test('- leaves a player that is really playing alone', () async {
      reportPlayer(playing: true, processingState: ProcessingState.ready);

      await target.play();

      verifyNever(player.pause);
      verify(player.play).called(1);
    });
  });

  group('reorder', () {
    TargetTrack trackNamed(String id) => TargetTrack(
      itemId: id,
      uri: Uri.parse('http://jelly.local:8096/Audio/$id/universal'),
      mimeType: 'audio/flac',
      isHls: false,
      title: id,
      duration: const Duration(minutes: 3),
    );

    late List<String> queue;

    setUp(() {
      queue = ['a', 'b', 'c', 'd'];
      when(() => player.sequence).thenReturn(
        List.filled(4, ProgressiveAudioSource(Uri.parse('http://a'))),
      );
      when(() => player.moveAudioSource(any(), any())).thenAnswer((
        invocation,
      ) async {
        final from = invocation.positionalArguments[0] as int;
        final to = invocation.positionalArguments[1] as int;
        queue.insert(to, queue.removeAt(from));
      });
    });

    test('- walks the queue into its new order one move at a time', () async {
      const order = [2, 0, 3, 1];

      await target.reorder(
        [for (final index in order) trackNamed(queue[index])],
        order: order,
        currentIndex: 1,
      );

      expect(queue, ['c', 'a', 'd', 'b']);
    });

    test('- moves nothing when the order already matches', () async {
      await target.reorder(
        [for (final id in queue) trackNamed(id)],
        order: [0, 1, 2, 3],
        currentIndex: 0,
      );

      verifyNever(() => player.moveAudioSource(any(), any()));
    });

    test('- leaves the queue alone when it is out of step', () async {
      await target.reorder(
        [trackNamed('a')],
        order: [0],
        currentIndex: 0,
      );

      verifyNever(() => player.moveAudioSource(any(), any()));
    });
  });

  group('replacing a queued source', () {
    setUp(() {
      when(() => player.sequence).thenReturn(
        List.filled(3, ProgressiveAudioSource(Uri.parse('http://a'))),
      );
      when(() => player.removeAudioSourceAt(any())).thenAnswer((_) async {});
      when(
        () => player.insertAudioSource(any(), any()),
      ).thenAnswer((_) async {});
    });

    test('- swaps the source sitting at that index', () async {
      when(() => player.shuffleModeEnabled).thenReturn(false);

      await target.replace(1, trackWith());

      verifyInOrder([
        () => player.removeAudioSourceAt(1),
        () => player.insertAudioSource(1, any()),
      ]);
    });

    test('- holds the entry in its shuffle slot', () async {
      when(() => player.shuffleModeEnabled).thenReturn(true);

      await target.load(
        [trackWith(), trackWith(), trackWith()],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: false,
      );
      final order =
          verify(
                () => player.setAudioSources(
                  any(),
                  initialIndex: any(named: 'initialIndex'),
                  initialPosition: any(named: 'initialPosition'),
                  preload: any(named: 'preload'),
                  shuffleOrder: captureAny(named: 'shuffleOrder'),
                ),
              ).captured.single
              as QueueShuffleOrder;
      order.indices.addAll([2, 0, 1]);

      await target.replace(1, trackWith());

      expect(order.nextInsertPosition, 2);
    });

    test('- skips an index the queue does not have yet', () async {
      when(() => player.shuffleModeEnabled).thenReturn(false);

      await target.replace(3, trackWith());

      verifyNever(() => player.removeAudioSourceAt(any()));
      verifyNever(() => player.insertAudioSource(any(), any()));
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

  group('a big queue', () {
    List<TargetTrack> tracks(int count) => [
      for (var i = 0; i < count; i++)
        TargetTrack(
          itemId: 'song-$i',
          uri: Uri.parse('http://jelly.local:8096/Audio/song-$i/universal'),
          mimeType: 'audio/flac',
          isHls: false,
          title: 'Track $i',
          duration: const Duration(minutes: 4),
        ),
    ];

    ({List<AudioSource> sources, int index}) lastLoad() {
      final captured = verify(
        () => player.setAudioSources(
          captureAny(),
          initialIndex: captureAny(named: 'initialIndex'),
          initialPosition: any(named: 'initialPosition'),
          preload: any(named: 'preload'),
          shuffleOrder: any(named: 'shuffleOrder'),
        ),
      ).captured;
      return (
        sources: captured[captured.length - 2] as List<AudioSource>,
        index: captured.last as int,
      );
    }

    String idOf(AudioSource source) =>
        ((source as UriAudioSource).tag as MediaItem).id;

    setUp(() {
      when(() => player.addAudioSources(any())).thenAnswer((_) async {});
      when(
        () => player.insertAudioSources(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => player.removeAudioSourceRange(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => player.insertAudioSource(any(), any()),
      ).thenAnswer((_) async {});
      when(() => player.removeAudioSourceAt(any())).thenAnswer((_) async {});
      when(() => player.loopMode).thenReturn(LoopMode.off);
    });

    Future<void> loadBig({int at = 500}) async {
      await target.load(
        tracks(1000),
        initialIndex: at,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      reportPlayer(
        playing: true,
        processingState: ProcessingState.ready,
        index: at - 470,
      );
    }

    test('- loads only a window around the starting track', () async {
      await loadBig();

      final load = lastLoad();
      expect(load.sources, hasLength(131));
      expect(idOf(load.sources.first), 'song-470');
      expect(idOf(load.sources.last), 'song-600');
      expect(load.index, 30);
    });

    test('- reports queue indices, not player slots', () async {
      await loadBig();
      indexes.add(30);
      await Future<void>.delayed(Duration.zero);

      expect(target.state.currentIndex, 500);
    });

    test(
      '- never removes more than half the slots ahead of the current one',
      () async {
        await loadBig();
        reportPlayer(
          playing: true,
          processingState: ProcessingState.ready,
          index: 66,
        );
        indexes.add(66);
        await Future<void>.delayed(Duration.zero);

        verifyInOrder([
          () => player.removeAudioSourceRange(0, 33),
          () => player.removeAudioSourceRange(0, 3),
        ]);
        verifyNever(() => player.removeAudioSourceRange(0, 36));
      },
    );

    test('- slides the window forward as playback nears its end', () async {
      await loadBig();
      reportPlayer(
        playing: true,
        processingState: ProcessingState.ready,
        index: 111,
      );
      indexes.add(111);
      await Future<void>.delayed(Duration.zero);

      final added =
          verify(() => player.addAudioSources(captureAny())).captured.single
              as List<AudioSource>;
      expect(added, hasLength(81));
      expect(idOf(added.first), 'song-601');
      expect(idOf(added.last), 'song-681');
      verifyInOrder([
        () => player.removeAudioSourceRange(0, 55),
        () => player.removeAudioSourceRange(0, 26),
      ]);
      verifyNever(() => player.removeAudioSourceRange(0, 81));
      reportPlayer(
        playing: true,
        processingState: ProcessingState.ready,
        index: 30,
      );
      indexes.add(30);
      await Future<void>.delayed(Duration.zero);
      expect(target.state.currentIndex, 581);
    });

    test('- waits for a head trim before seeking to a slot', () async {
      await loadBig();
      final trimming = Completer<void>();
      when(
        () => player.removeAudioSourceRange(0, 55),
      ).thenAnswer((_) => trimming.future);
      reportPlayer(
        playing: true,
        processingState: ProcessingState.ready,
        index: 111,
      );
      indexes.add(111);
      await Future<void>.delayed(Duration.zero);

      final jump = target.skipTo(560);
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => player.seek(any(), index: any(named: 'index')));
      trimming.complete();
      await jump;

      verify(() => player.seek(Duration.zero, index: 9)).called(1);
    });

    test('- reloads the window for a jump far outside it', () async {
      await loadBig();
      await target.skipTo(10);

      final load = lastLoad();
      expect(load.sources, hasLength(111));
      expect(idOf(load.sources.first), 'song-0');
      expect(load.index, 10);
      verifyNever(() => player.seek(any(), index: any(named: 'index')));
      reportPlayer(
        playing: true,
        processingState: ProcessingState.ready,
        index: 10,
      );
      indexes.add(10);
      await Future<void>.delayed(Duration.zero);
      expect(target.state.currentIndex, 10);
    });

    test('- seeks within the window without reloading', () async {
      await loadBig();
      await target.skipTo(520);

      verify(() => player.seek(Duration.zero, index: 50)).called(1);
    });

    test('- keeps indices straight when the queue is edited', () async {
      await loadBig();
      await target.insert(0, tracks(1).single);
      verifyNever(() => player.insertAudioSource(any(), any()));
      indexes.add(30);
      await Future<void>.delayed(Duration.zero);
      expect(target.state.currentIndex, 501);

      await target.remove(0);
      indexes.add(30);
      await Future<void>.delayed(Duration.zero);
      expect(target.state.currentIndex, 500);

      await target.insert(501, tracks(1).single);
      verify(() => player.insertAudioSource(31, any())).called(1);
    });

    test('- moves within the window as a single player move', () async {
      await loadBig();
      when(() => player.moveAudioSource(any(), any())).thenAnswer((_) async {});

      await target.move(520, 480);

      verify(() => player.moveAudioSource(50, 10)).called(1);
      verifyNever(() => player.removeAudioSourceRange(any(), any()));
      indexes.add(30);
      await Future<void>.delayed(Duration.zero);
      expect(target.state.currentIndex, 500);
    });
  });

  group('a player between sessions', () {
    test(
      '- absorbs the dead channel a stopped service leaves behind',
      () async {
        when(() => player.setVolume(any())).thenThrow(
          MissingPluginException('setVolume'),
        );

        final target = LocalPlaybackTarget(player);
        addTearDown(target.dispose);

        await expectLater(target.setVolume(0.4), completes);
      },
    );
  });
}
