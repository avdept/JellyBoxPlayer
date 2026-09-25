import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:optional_features/jellybox_cloud.dart';

final outputControllerProvider = Provider<OutputController>(
  OutputController.new,
);

class OutputController {
  OutputController(this._ref);

  final Ref _ref;

  PlaybackNotifier get _playback => _ref.read(playbackProvider.notifier);

  Future<void> playHere() => playOn(_ref.read(localPlaybackTargetProvider));

  Future<void> playOn(PlaybackTarget target) async {
    if (!_ref.read(playingElsewhereProvider)) {
      await _playback.switchTarget(target);
      return;
    }

    await _playback.switchTarget(target, carryQueue: false);
    final claimed = await _ref.read(cloudProvider.notifier).claimHere();
    if (!claimed) await _playback.reloadOnTarget();
  }

  Future<void> handOffTo(ConductorDevice device) async {
    await _ref.read(cloudProvider.notifier).handoffTo(device.id);
    if (_playback.target.kind != PlaybackTargetKind.local) {
      await _playback.switchTarget(_ref.read(localPlaybackTargetProvider));
    }
  }
}
