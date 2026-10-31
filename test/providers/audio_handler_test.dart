import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/providers/audio_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _MockSequenceState extends Mock implements SequenceState {}

void main() {
  late _MockAudioPlayer player;
  late StreamController<PlaybackEvent> events;
  late StreamController<PlayerState> playerStates;
  late StreamController<SequenceState> sequences;
  late JellyBoxAudioHandler handler;
  late List<PlaybackState> pushed;

  setUp(() {
    player = _MockAudioPlayer();
    events = StreamController<PlaybackEvent>.broadcast();
    playerStates = StreamController<PlayerState>.broadcast();
    sequences = StreamController<SequenceState>.broadcast();
    when(() => player.playbackEventStream).thenAnswer((_) => events.stream);
    when(() => player.playerStateStream).thenAnswer((_) => playerStates.stream);
    when(() => player.sequenceStateStream).thenAnswer((_) => sequences.stream);
    when(() => player.playing).thenReturn(true);
    when(() => player.processingState).thenReturn(ProcessingState.ready);
    when(() => player.currentIndex).thenReturn(0);
    when(() => player.speed).thenReturn(1);
    when(() => player.position).thenReturn(Duration.zero);
    when(() => player.bufferedPosition).thenReturn(Duration.zero);

    handler = JellyBoxAudioHandler(player);
    pushed = [];
    handler.playbackState.skip(1).listen(pushed.add);
  });

  tearDown(() async {
    await events.close();
    await playerStates.close();
    await sequences.close();
  });

  void tick(Duration position) {
    when(() => player.position).thenReturn(position);
    events.add(PlaybackEvent(updatePosition: position));
  }

  test('- coalesces position-only events while playing', () async {
    for (var ms = 0; ms <= 100; ms += 20) {
      tick(Duration(milliseconds: ms));
    }
    await pumpEventQueue();

    expect(pushed, hasLength(1));

    await Future<void>.delayed(JellyBoxAudioHandler.positionInterval);
    tick(const Duration(milliseconds: 400));
    await pumpEventQueue();

    expect(pushed, hasLength(2));
    expect(pushed.last.updatePosition, const Duration(milliseconds: 400));
  });

  test('- pushes a track change straight away', () async {
    tick(Duration.zero);
    await pumpEventQueue();
    when(() => player.currentIndex).thenReturn(1);
    tick(Duration.zero);
    await pumpEventQueue();

    expect(pushed.map((state) => state.queueIndex), [0, 1]);
  });

  test('- passes every event while paused', () async {
    when(() => player.playing).thenReturn(false);
    tick(const Duration(seconds: 10));
    tick(const Duration(seconds: 20));
    await pumpEventQueue();

    expect(pushed, hasLength(2));
  });

  test('- adds the current item once, not on every sequence event', () async {
    const item = MediaItem(id: 'song-1', title: 'Roads');
    final source = AudioSource.uri(Uri.parse('http://jelly.local'), tag: item);
    final sequence = _MockSequenceState();
    when(() => sequence.currentSource).thenReturn(source);
    final items = <MediaItem?>[];
    handler.mediaItem.skip(1).listen(items.add);

    for (var i = 0; i < 5; i++) {
      sequences.add(sequence);
    }
    await pumpEventQueue();

    expect(items, [item]);
  });
}
