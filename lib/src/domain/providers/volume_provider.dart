import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/system_volume_provider.dart';

const _fallbackLevel = 0.5;
const _rendererStartLevel = 0.1;

double savedRendererLevel(AppSettingsNotifier settings, String targetId) =>
    settings.rendererVolume(targetId) ?? _rendererStartLevel;

class VolumeState {
  const VolumeState({required this.level, this.muted = false});

  final double level;
  final bool muted;

  double get effectiveLevel => muted ? 0 : level;

  bool get isSilent => effectiveLevel == 0;
}

final volumeProvider = StateNotifierProvider<VolumeNotifier, VolumeState>((
  ref,
) {
  final target = ref.watch(playbackTargetProvider);
  return VolumeNotifier(
    target,
    ref.watch(appSettingsProvider.notifier),
    pinnedToFull:
        ref.watch(usesSystemVolumeProvider) &&
        target.kind == PlaybackTargetKind.local,
  );
});

class VolumeNotifier extends StateNotifier<VolumeState> {
  VolumeNotifier(
    PlaybackTarget target,
    AppSettingsNotifier settings, {
    this.pinnedToFull = false,
  }) : _target = target,
       _settings = settings,
       super(
         VolumeState(
           level: pinnedToFull
               ? 1
               : settings.numberOf(AppSetting.playerVolume).clamp(0.0, 1.0),
         ),
       ) {
    _lastAudibleLevel = state.level > 0 ? state.level : _fallbackLevel;
    if (_target.kind == PlaybackTargetKind.local) {
      unawaited(_target.setVolume(state.effectiveLevel));
    } else {
      unawaited(_startRendererVolume());
    }
  }

  final PlaybackTarget _target;
  final AppSettingsNotifier _settings;
  final bool pinnedToFull;

  late double _lastAudibleLevel;

  Future<void> _startRendererVolume() async {
    final level = savedRendererLevel(_settings, _target.id);
    if (mounted) {
      _lastAudibleLevel = level > 0 ? level : _fallbackLevel;
      state = VolumeState(level: level);
    }
    await _target.setVolume(level);
  }

  Future<void> setLevel(double value, {bool persist = true}) async {
    if (pinnedToFull) return;
    final level = value.clamp(0.0, 1.0);
    if (level > 0) _lastAudibleLevel = level;
    state = VolumeState(level: level);
    if (persist) {
      if (_target.kind == PlaybackTargetKind.local) {
        _settings.setNumber(AppSetting.playerVolume, level);
      } else {
        _settings.setRendererVolume(_target.id, level);
      }
    }
    return _target.setVolume(level);
  }

  Future<void> toggleMute() async {
    if (pinnedToFull) return;
    if (!state.muted) {
      state = VolumeState(level: state.level, muted: true);
      return _target.setVolume(0);
    }
    return setLevel(state.level > 0 ? state.level : _lastAudibleLevel);
  }
}
