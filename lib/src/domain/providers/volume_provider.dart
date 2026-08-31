import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';

const _fallbackLevel = 0.5;

class VolumeState {
  const VolumeState({required this.level, this.muted = false});

  final double level;
  final bool muted;

  double get effectiveLevel => muted ? 0 : level;

  bool get isSilent => effectiveLevel == 0;
}

final volumeProvider = StateNotifierProvider<VolumeNotifier, VolumeState>(
  (ref) => VolumeNotifier(
    ref.watch(playerProvider),
    ref.watch(appSettingsProvider.notifier),
  ),
);

class VolumeNotifier extends StateNotifier<VolumeState> {
  VolumeNotifier(AudioPlayer player, AppSettingsNotifier settings)
    : _player = player,
      _settings = settings,
      super(
        VolumeState(
          level: settings.numberOf(AppSetting.playerVolume).clamp(0.0, 1.0),
        ),
      ) {
    _lastAudibleLevel = state.level > 0 ? state.level : _fallbackLevel;
    unawaited(_player.setVolume(state.effectiveLevel));
  }

  final AudioPlayer _player;
  final AppSettingsNotifier _settings;

  late double _lastAudibleLevel;

  Future<void> setLevel(double value, {bool persist = true}) {
    final level = value.clamp(0.0, 1.0);
    if (level > 0) _lastAudibleLevel = level;
    state = VolumeState(level: level);
    if (persist) _settings.setNumber(AppSetting.playerVolume, level);
    return _player.setVolume(level);
  }

  Future<void> toggleMute() {
    if (!state.muted) {
      state = VolumeState(level: state.level, muted: true);
      return _player.setVolume(0);
    }
    return setLevel(state.level > 0 ? state.level : _lastAudibleLevel);
  }
}
