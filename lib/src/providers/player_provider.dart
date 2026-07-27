import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/providers/audio_handler.dart';
import 'package:just_audio/just_audio.dart';

var _audioServiceInitialized = false;

final playerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  // On iOS/Android the media notification is handled by just_audio_background
  // (initialised in main.dart). On desktop — notably Linux, for MPRIS media
  // keys — we init audio_service with our own handler instead. Running both on
  // mobile makes this second init override just_audio_background, which breaks
  // the notification icon (falls back to the opaque launcher icon).
  final isMobile = Platform.isIOS || Platform.isAndroid;
  if (!isMobile && !_audioServiceInitialized) {
    _audioServiceInitialized = true;
    AudioService.init(
      builder: () => JellyBoxAudioHandler(player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
        androidNotificationChannelName: 'Audio playback',
      ),
    );
  }
  return player;
});
