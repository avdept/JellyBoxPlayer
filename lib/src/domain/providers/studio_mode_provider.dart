import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

bool get supportsWindowFullscreen =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

bool get supportsKeepScreenOn =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

const minWindowSize = kDebugMode ? Size(360, 600) : Size(1280, 800);

final studioModeVisibleProvider = StateProvider<bool>((ref) => false);

final studioModeLyricsProvider = Provider<bool>(
  (ref) => ref.watch(settingProvider(AppSetting.studioModeLyrics)),
);

final studioModeShownProvider = Provider<bool>((ref) {
  if (!ref.watch(studioModeVisibleProvider)) return false;
  return ref.watch(currentSongProvider.select((song) => song != null));
});
