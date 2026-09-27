import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/presentation/utils/playback_time.dart';

void main() {
  const position = Duration(minutes: 1, seconds: 5, milliseconds: 700);
  const duration = Duration(minutes: 4, seconds: 30);

  String label(PlayerTimeDisplay display) =>
      playerTimeLabel(display, position: position, duration: duration);

  test('- each mode renders its own label', () {
    expect(label(PlayerTimeDisplay.remaining), '-3:25');
    expect(label(PlayerTimeDisplay.elapsed), '1:05');
    expect(label(PlayerTimeDisplay.elapsedAndTotal), '1:05 / 4:30');
  });

  test('- tapping cycles remaining, elapsed, elapsed/total and back', () {
    expect(PlayerTimeDisplay.remaining.next, PlayerTimeDisplay.elapsed);
    expect(PlayerTimeDisplay.elapsed.next, PlayerTimeDisplay.elapsedAndTotal);
    expect(PlayerTimeDisplay.elapsedAndTotal.next, PlayerTimeDisplay.remaining);
  });

  test('- hour-long tracks keep padded minutes', () {
    expect(
      formatPlaybackTime(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });
}
