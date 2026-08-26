import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

bool get supportsWindowFullscreen =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

final studioModeVisibleProvider = StateProvider<bool>((ref) => false);

final studioModeShownProvider = Provider<bool>((ref) {
  if (!ref.watch(studioModeVisibleProvider)) return false;
  return ref.watch(currentSongProvider.select((song) => song != null));
});
