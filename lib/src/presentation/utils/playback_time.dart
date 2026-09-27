import 'package:jplayer/src/core/enums/enums.dart';

String formatPlaybackTime(Duration value) {
  final duration = value < Duration.zero ? Duration.zero : value;
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    final mm = minutes.toString().padLeft(2, '0');
    return '$hours:$mm:$ss';
  }
  return '${duration.inMinutes}:$ss';
}

String playerTimeLabel(
  PlayerTimeDisplay display, {
  required Duration position,
  required Duration duration,
}) {
  final elapsed = Duration(seconds: position.inSeconds);
  return switch (display) {
    PlayerTimeDisplay.remaining => '-${formatPlaybackTime(duration - elapsed)}',
    PlayerTimeDisplay.elapsed => formatPlaybackTime(elapsed),
    PlayerTimeDisplay.elapsedAndTotal =>
      '${formatPlaybackTime(elapsed)} / ${formatPlaybackTime(duration)}',
  };
}
