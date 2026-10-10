import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/queue_shuffle_order.dart';
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

    test('- stops the player after staying paused', () async {
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
      }) {
        final retrying = LocalPlaybackTarget(
          player,
          isOnline: () => isOnline,
          onlineChanges: () => online.stream,
          retryDelays: [retryDelay],
          offlineRetryEvery: offlineRetryEvery,
          skipAfter: skipAfter,
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
