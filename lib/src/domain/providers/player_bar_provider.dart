import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/now_playing_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:optional_features/jellybox_cloud.dart';

class BarProgress {
  const BarProgress({
    required this.position,
    required this.duration,
    this.buffered = Duration.zero,
    this.stopped = false,
  });

  final Duration position;
  final Duration duration;
  final Duration buffered;
  final bool stopped;

  Duration get remaining => duration - position;
}

final barSongProvider = Provider<LibraryItem?>(
  (ref) => ref.watch(playingElsewhereProvider)
      ? ref.watch(remoteNowPlayingProvider)
      : ref.watch(currentSongProvider),
);

final barMediaQueueProvider = Provider<List<MediaItem>>((ref) {
  if (!ref.watch(playingElsewhereProvider)) {
    return ref.watch(nowPlayingQueueProvider);
  }
  final images = ref.watch(imageServiceProvider);
  return [
    for (final song in ref.watch(barQueueProvider))
      mediaItemFor(song, images: images),
  ];
});

final barMediaItemProvider = Provider<MediaItem?>((ref) {
  if (!ref.watch(playingElsewhereProvider)) {
    return ref.watch(nowPlayingProvider);
  }
  final song = ref.watch(remoteNowPlayingProvider);
  if (song == null) return null;
  return mediaItemFor(song, images: ref.watch(imageServiceProvider));
});

final barHasQueueProvider = Provider<bool>(
  (ref) => ref.watch(playingElsewhereProvider) || ref.watch(hasQueueProvider),
);

final barQueueProvider = Provider<List<LibraryItem>>(
  (ref) => ref.watch(playingElsewhereProvider)
      ? ref.watch(remoteQueueProvider).valueOrNull ?? const []
      : ref.watch(playbackProvider.select((state) => state.songs)),
);

final barQueueIndexProvider = Provider<int?>(
  (ref) => ref.watch(playingElsewhereProvider)
      ? ref.watch(
          remoteSessionProvider.select((remote) => remote?.doc.queuePosition),
        )
      : ref.watch(playbackProvider.select((state) => state.currentMediaIndex)),
);

final barPlayingProvider = Provider<bool>(
  (ref) => ref.watch(playingElsewhereProvider)
      ? ref.watch(
          remoteSessionProvider.select(
            (remote) => remote?.doc.playing ?? false,
          ),
        )
      : ref.watch(
          playbackProvider.select(
            (state) => state.status == PlaybackStatus.playing,
          ),
        ),
);

final AutoDisposeProvider<BarProgress>
barProgressProvider = Provider.autoDispose<BarProgress>((ref) {
  if (ref.watch(playingElsewhereProvider)) {
    return BarProgress(
      position: ref.watch(remotePositionProvider),
      duration: ref.watch(remoteNowPlayingProvider)?.duration ?? Duration.zero,
    );
  }
  return ref.watch(
    playbackProvider.select(
      (state) => BarProgress(
        position: state.position.isNegative ? Duration.zero : state.position,
        duration: state.totalDuration ?? Duration.zero,
        buffered: state.cacheProgress,
        stopped: state.status == PlaybackStatus.stopped,
      ),
    ),
  );
});

final barShuffleProvider = Provider<bool>(
  (ref) => ref.watch(playingElsewhereProvider)
      ? ref.watch(
          remoteSessionProvider.select(
            (remote) => remote?.doc.shuffle ?? false,
          ),
        )
      : ref.watch(playbackProvider.select((state) => state.shuffleEnabled)),
);

final _localLoopModeProvider = StreamProvider<LoopMode>(
  (ref) => ref.watch(playerProvider).loopModeStream,
);

final barRepeatProvider = Provider<LoopMode>((ref) {
  if (ref.watch(playingElsewhereProvider)) {
    final mode = ref.watch(
      remoteSessionProvider.select((remote) => remote?.doc.repeat),
    );
    return LoopMode.values.asNameMap()[mode] ?? LoopMode.off;
  }
  return ref.watch(_localLoopModeProvider).valueOrNull ??
      ref.read(playerProvider).loopMode;
});

final barControlsProvider = Provider<BarControls>(BarControls.new);

class BarControls {
  BarControls(this._ref);

  final Ref _ref;

  bool get _remote => _ref.read(playingElsewhereProvider);

  PlaybackNotifier get _local => _ref.read(playbackProvider.notifier);

  Future<void> _send(PlayerCommand command, [Object? value]) =>
      _ref.read(cloudProvider.notifier).sendCommand(command, value: value);

  Future<void> togglePlay() {
    if (!_remote) return _local.playPause();
    final playing = _ref.read(barPlayingProvider);
    return _send(playing ? PlayerCommand.pause : PlayerCommand.play);
  }

  Future<void> next() => _remote ? _send(PlayerCommand.next) : _local.next();

  Future<void> previous() =>
      _remote ? _send(PlayerCommand.previous) : _local.prev();

  Future<void> seek(Duration position) => _remote
      ? _send(PlayerCommand.seek, position.inMilliseconds)
      : _local.seek(position);

  Future<void> setShuffle({required bool enabled}) => _remote
      ? _send(PlayerCommand.shuffle, enabled)
      : _local.setShuffle(enabled: enabled);

  Future<void> setRepeat(LoopMode mode) => _remote
      ? _send(PlayerCommand.repeat, mode.name)
      : _ref.read(playerProvider).setLoopMode(mode);

  Future<bool> toggleFavourite(LibraryItem song) async {
    if (_ref.read(isOfflineProvider)) return false;
    final favorite = !song.userData.isFavorite;
    try {
      await _ref
          .read(mediaServerClientProvider)
          .setFavorite(song.id, favorite: favorite);
    } on Object {
      return false;
    }
    _ref.invalidate(favouriteSongsProvider);
    if (_remote) _ref.invalidate(remoteQueueProvider);
    _local.updateSong(
      song.copyWith(userData: song.userData.copyWith(isFavorite: favorite)),
    );
    return true;
  }

  Future<void> skipTo(int index, {bool autoPlay = true}) => _remote
      ? _send(PlayerCommand.skipTo, index)
      : _local.skipTo(index, autoPlay: autoPlay);
}
