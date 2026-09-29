import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

bool get supportsWindowFullscreen =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

const minWindowSize = kDebugMode ? Size(360, 600) : Size(1280, 800);

final studioModeVisibleProvider = StateProvider<bool>((ref) => false);

final studioModeLyricsProvider = StateProvider<bool>((ref) => false);

final studioModeShownProvider = Provider<bool>((ref) {
  if (!ref.watch(studioModeVisibleProvider)) return false;
  return ref.watch(currentSongProvider.select((song) => song != null));
});
