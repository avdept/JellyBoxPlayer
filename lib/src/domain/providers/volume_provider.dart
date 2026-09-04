import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';

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
    ref.watch(playbackTargetProvider),
    ref.watch(appSettingsProvider.notifier),
  ),
);

class VolumeNotifier extends StateNotifier<VolumeState> {
  VolumeNotifier(PlaybackTarget target, AppSettingsNotifier settings)
    : _target = target,
      _settings = settings,
      super(
        VolumeState(
          level: settings.numberOf(AppSetting.playerVolume).clamp(0.0, 1.0),
        ),
      ) {
    _lastAudibleLevel = state.level > 0 ? state.level : _fallbackLevel;
    if (_target.kind == PlaybackTargetKind.local) {
      unawaited(_target.setVolume(state.effectiveLevel));
    } else {
      unawaited(_adoptTargetVolume());
    }
  }

  final PlaybackTarget _target;
  final AppSettingsNotifier _settings;

  late double _lastAudibleLevel;

  Future<void> _adoptTargetVolume() async {
    final level = await _target.currentVolume();
    if (level == null || !mounted) return;
    _lastAudibleLevel = level > 0 ? level : _fallbackLevel;
    state = VolumeState(level: level);
  }

  Future<void> setLevel(double value, {bool persist = true}) {
    final level = value.clamp(0.0, 1.0);
    if (level > 0) _lastAudibleLevel = level;
    state = VolumeState(level: level);
    if (persist && _target.kind == PlaybackTargetKind.local) {
      _settings.setNumber(AppSetting.playerVolume, level);
    }
    return _target.setVolume(level);
  }

  Future<void> toggleMute() {
    if (!state.muted) {
      state = VolumeState(level: state.level, muted: true);
      return _target.setVolume(0);
    }
    return setLevel(state.level > 0 ? state.level : _lastAudibleLevel);
  }
}
