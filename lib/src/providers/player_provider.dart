import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/providers/audio_handler.dart';
import 'package:just_audio/just_audio.dart';

var _audioServiceInitialized = false;

final playerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  if (!_audioServiceInitialized) {
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
