import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/playback/default_output.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:optional_features/jellybox_cloud.dart';

final outputControllerProvider = Provider<OutputController>(
  OutputController.new,
);

class OutputController {
  OutputController(this._ref) {
    _ref.listen<DefaultOutput?>(
      defaultOutputProvider,
      (previous, next) {
        if (previous != next) _defaultOverridden = false;
      },
    );
  }

  final Ref _ref;
  var _defaultOverridden = false;

  PlaybackNotifier get _playback => _ref.read(playbackProvider.notifier);

  Future<void> playHere() => playOn(_ref.read(localPlaybackTargetProvider));

  Future<void> choose(PlaybackTarget target) {
    _defaultOverridden =
        _ref.read(defaultOutputProvider)?.targetId != target.id;
    return playOn(target);
  }

  Future<void> chooseHere() {
    overrideDefault();
    return playHere();
  }

  void overrideDefault() => _defaultOverridden = true;

  DefaultOutput? get pendingDefault {
    final wanted = _ref.read(defaultOutputProvider);
    if (wanted == null || _defaultOverridden || !wanted.reachableHere) {
      return null;
    }
    if (_playback.target.kind != PlaybackTargetKind.local) return null;
    if (_ref.read(playingElsewhereProvider)) return null;
    if (_ref.read(isOfflineProvider) || _ref.read(manualOfflineProvider)) {
      return null;
    }
    return wanted;
  }

  Future<bool> moveToDefault(DefaultOutput wanted) async {
    final target = await _ref.read(defaultOutputFinderProvider).find(wanted);
    if (target == null) return false;
    if (_playback.target.kind != PlaybackTargetKind.local) return true;
    await _playback.switchTarget(target, carryQueue: false);
    return true;
  }

  Future<void> playOn(PlaybackTarget target) async {
    if (!_ref.read(playingElsewhereProvider)) {
      await _playback.switchTarget(target);
      return;
    }

    await _playback.switchTarget(target, carryQueue: false);
    final claimed = await _ref.read(cloudProvider.notifier).claimHere();
    if (!claimed) await _playback.reloadOnTarget();
  }

  Future<bool> handOffTo(ConductorDevice device) async {
    final taken = await _ref.read(cloudProvider.notifier).handoffTo(device.id);
    if (taken && _playback.target.kind != PlaybackTargetKind.local) {
      await _playback.switchTarget(_ref.read(localPlaybackTargetProvider));
    }
    return taken;
  }
}
