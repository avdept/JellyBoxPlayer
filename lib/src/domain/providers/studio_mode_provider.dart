import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/shared_preferences_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool get supportsWindowFullscreen =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows);

final studioModeVisibleProvider = StateProvider<bool>((ref) => false);

final studioModeShownProvider = Provider<bool>((ref) {
  if (!ref.watch(studioModeVisibleProvider)) return false;
  return ref.watch(currentSongProvider.select((song) => song != null));
});

final studioModeFullscreenProvider =
    StateNotifierProvider<BoolPrefNotifier, bool>(
      (ref) => BoolPrefNotifier(
        ref.watch(sharedPreferencesProvider).valueOrNull,
        key: 'studio_mode_fullscreen',
      ),
    );

final studioModeAnimationProvider =
    StateNotifierProvider<BoolPrefNotifier, bool>(
      (ref) => BoolPrefNotifier(
        ref.watch(sharedPreferencesProvider).valueOrNull,
        key: 'studio_mode_animation',
        defaultValue: true,
      ),
    );

class BoolPrefNotifier extends StateNotifier<bool> {
  BoolPrefNotifier(
    this._prefs, {
    required String key,
    bool defaultValue = false,
  }) : _key = key,
       super(_prefs?.getBool(key) ?? defaultValue);

  final SharedPreferences? _prefs;
  final String _key;

  bool get enabled => state;

  set enabled(bool value) {
    state = value;
    final prefs = _prefs;
    if (prefs != null) unawaited(prefs.setBool(_key, value));
  }
}
