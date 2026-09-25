import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/system_volume_provider.dart';
import 'package:jplayer/src/domain/providers/volume_provider.dart';
import 'package:optional_features/jellybox_cloud.dart';

enum VolumeScope { remote, system, player }

final volumeScopeProvider = Provider<VolumeScope>((ref) {
  if (ref.watch(playingElsewhereProvider)) return VolumeScope.remote;
  final local =
      ref.watch(playbackTargetProvider.select((target) => target.kind)) ==
      PlaybackTargetKind.local;
  if (local && ref.watch(usesSystemVolumeProvider)) return VolumeScope.system;
  return VolumeScope.player;
});

final deviceVolumeProvider =
    StateNotifierProvider<DeviceVolumeNotifier, VolumeState>(
      (ref) => DeviceVolumeNotifier(ref, ref.watch(volumeScopeProvider)),
    );

class DeviceVolumeNotifier extends StateNotifier<VolumeState> {
  DeviceVolumeNotifier(this._ref, this.scope)
    : super(const VolumeState(level: 1)) {
    switch (scope) {
      case VolumeScope.remote:
        _ref.listen(
          remoteSessionProvider.select((remote) => remote?.doc.volume ?? 1),
          (_, level) => _reported(level),
          fireImmediately: true,
        );
      case VolumeScope.system:
        _ref.listen(
          systemVolumeProvider,
          (_, level) => _reported(level),
          fireImmediately: true,
        );
      case VolumeScope.player:
        _ref.listen(
          volumeProvider,
          (_, volume) => state = volume,
          fireImmediately: true,
        );
    }
  }

  static const sendInterval = Duration(milliseconds: 150);
  static const holdFor = Duration(seconds: 2);

  final Ref _ref;
  final VolumeScope scope;

  Timer? _sendTimer;
  Timer? _holdTimer;
  double? _pending;
  double? _lastReported;
  double _lastAudible = 0.5;

  double get level => state.effectiveLevel;

  void _reported(double level) {
    _lastReported = level;
    if (_holdTimer?.isActive ?? false) return;
    if (level > 0) _lastAudible = level;
    state = VolumeState(level: level);
  }

  Future<void> setLevel(double value, {bool settle = true}) async {
    if (scope == VolumeScope.player) {
      return _ref
          .read(volumeProvider.notifier)
          .setLevel(value, persist: settle);
    }

    final level = value.clamp(0.0, 1.0);
    if (level > 0) _lastAudible = level;
    state = VolumeState(level: level);

    if (scope == VolumeScope.system) {
      return _ref.read(systemVolumeProvider.notifier).setLevel(level);
    }

    _holdTimer?.cancel();
    _holdTimer = Timer(holdFor, () {
      final reported = _lastReported;
      if (mounted && reported != null) _reported(reported);
    });
    _pending = level;
    if (settle) {
      _sendTimer?.cancel();
      _sendTimer = null;
      await _flush();
    } else {
      _sendTimer ??= Timer(sendInterval, () {
        _sendTimer = null;
        unawaited(_flush());
      });
    }
  }

  Future<void> toggleMute() {
    if (scope == VolumeScope.player) {
      return _ref.read(volumeProvider.notifier).toggleMute();
    }
    return setLevel(level > 0 ? 0 : _lastAudible);
  }

  Future<void> _flush() async {
    final level = _pending;
    if (level == null || !mounted) return;
    _pending = null;
    await _ref
        .read(cloudProvider.notifier)
        .sendCommand(PlayerCommand.volume, value: level);
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }
}
