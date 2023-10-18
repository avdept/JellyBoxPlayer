import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final playerProvider = StateProvider<AudioPlayer>((ref) {
  return AudioPlayer();
});
