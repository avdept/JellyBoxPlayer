import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/playback/local_playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/providers/player_provider.dart';

final localPlaybackTargetProvider = Provider<PlaybackTarget>((ref) {
  final target = LocalPlaybackTarget(ref.watch(playerProvider));
  ref.onDispose(target.dispose);
  return target;
});

class PlaybackTargetNotifier extends StateNotifier<PlaybackTarget> {
  PlaybackTargetNotifier(this.local) : super(local);

  final PlaybackTarget local;

  void select(PlaybackTarget target) {
    if (target.id == state.id) return;
    state = target;
  }

  void useLocal() => select(local);
}

final playbackTargetProvider =
    StateNotifierProvider<PlaybackTargetNotifier, PlaybackTarget>(
      (ref) => PlaybackTargetNotifier(ref.watch(localPlaybackTargetProvider)),
    );
