import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/car/car_content.dart';
import 'package:jplayer/src/domain/playback/playback_toggles.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

class WidgetCommands {
  static const channel = MethodChannel('com.prodigytech.jellybox/widget');

  static void initialize(ProviderContainer ref, CarContent content) {
    if (!Platform.isIOS) return;
    channel.setMethodCallHandler(
      (call) => handle(ref, call.method, argument: call.arguments as String?),
    );
    _content = content;
  }

  static CarContent? _content;

  static Future<void> handle(
    ProviderContainer ref,
    String command, {
    String? argument,
    CarContent? content,
  }) async {
    if (command == 'playAlbum') {
      final albums = content ?? _content;
      if (argument == null || albums == null) return;
      await ref.read(authProvider.future);
      return albums.play('album', argument);
    }
    final playback = ref.read(playbackProvider.notifier);
    final toggles = PlaybackToggles(ref);
    if (ref.read(playbackProvider).songs.isEmpty) {
      if (command == 'playPause') JustAudioBackground.rememberPlay();
      return;
    }
    switch (command) {
      case 'playPause':
        await playback.playPause();
      case 'next':
        await playback.next();
      case 'previous':
        await playback.prev();
      case 'like':
        await toggles.toggleFavourite();
      case 'shuffle':
        await toggles.toggleShuffle();
      case 'repeat':
        await toggles.toggleRepeat();
      default:
        throw MissingPluginException(command);
    }
  }
}
