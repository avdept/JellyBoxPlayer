import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/volume_fade.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockAudioPlayer player;
  late VolumeFade fade;
  late List<Object> calls;

  setUp(() {
    player = MockAudioPlayer();
    calls = [];
    when(player.play).thenAnswer((_) async => calls.add('play'));
    when(player.pause).thenAnswer((_) async => calls.add('pause'));
    when(player.stop).thenAnswer((_) async => calls.add('stop'));
    when(() => player.setVolume(any())).thenAnswer(
      (invocation) async => calls.add(
        (invocation.positionalArguments.single as double).toStringAsFixed(2),
      ),
    );
    when(() => player.playing).thenReturn(false);
    fade = VolumeFade.of(player);
  });

  test('one fade per player', () {
    expect(VolumeFade.of(player), same(fade));
    expect(VolumeFade.of(MockAudioPlayer()), isNot(same(fade)));
  });

  test('play starts silent and ramps up to the level', () async {
    await fade.setLevel(0.8);

    await fade.play();

    expect(calls, [
      '0.80',
      '0.00',
      'play',
      '0.16',
      '0.32',
      '0.48',
      '0.64',
      '0.80',
    ]);
  });

  test('play ramps up while the player is still playing', () async {
    final finished = Completer<void>();
    when(player.play).thenAnswer((_) {
      calls.add('play');
      return finished.future;
    });
    await fade.setLevel(0.8);

    final playing = fade.play();
    await Future<void>.delayed(VolumeFade.duration * 2);

    expect(calls.last, '0.80');
    finished.complete();
    await playing;
  });

  test('pause ramps down, pauses, then puts the level back', () async {
    await fade.setLevel(0.8);
    when(() => player.playing).thenReturn(true);

    await fade.pause();

    expect(calls, [
      '0.80',
      '0.64',
      '0.48',
      '0.32',
      '0.16',
      '0.00',
      'pause',
      '0.80',
    ]);
  });

  test('stop ramps down the same way', () async {
    await fade.setLevel(0.8);
    when(() => player.playing).thenReturn(true);

    await fade.stop();

    expect(calls.sublist(5), ['0.00', 'stop', '0.80']);
  });

  test('a paused player pauses at once', () async {
    await fade.pause();

    expect(calls, ['pause', '1.00']);
  });

  test('a silent level plays without a ramp', () async {
    await fade.setLevel(0);

    await fade.play();

    expect(calls, ['0.00', 'play']);
  });

  test('a level change during the ramp wins', () async {
    await fade.setLevel(0.8);

    final playing = fade.play();
    await fade.setLevel(0.3);
    await playing;

    expect(calls.last, '0.30');
    expect(fade.level, 0.3);
  });

  test('play during a pause ramp cancels the pause', () async {
    await fade.setLevel(0.8);
    when(() => player.playing).thenReturn(true);

    final pausing = fade.pause();
    await Future<void>.delayed(VolumeFade.duration ~/ VolumeFade.steps);
    await fade.play();
    await pausing;

    expect(calls, isNot(contains('pause')));
    expect(calls, contains('play'));
    expect(calls.last, '0.80');
  });

  test('a player between sessions is tolerated', () async {
    when(
      () => player.setVolume(any()),
    ).thenThrow(MissingPluginException('setVolume'));

    await expectLater(fade.setLevel(0.4), completes);
    expect(fade.level, 0.4);
  });
}
