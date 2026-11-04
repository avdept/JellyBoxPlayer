import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

Future<void> playWithSession(AudioPlayer player) async {
  try {
    await player.play();
  } on Object catch (error) {
    debugPrint('[Session] play refused by the audio session: $error');
    await player.pause();
  }
}
