import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/dto/dto.dart';

export 'package:jplayer/src/core/enums/enums.dart' show PlaybackStatus;

part 'playback_state.freezed.dart';

@freezed
abstract class PlaybackState with _$PlaybackState {
  const factory PlaybackState({
    required ItemDTO? album,
    required List<ItemDTO> songs,
    required PlaybackStatus status,
    required Duration position,
    required Duration cacheProgress,
    Duration? totalDuration,
    int? currentMediaIndex,
  }) = _PlaybackState;

  factory PlaybackState.initial() => const PlaybackState(
    album: null,
    songs: [],
    status: PlaybackStatus.stopped,
    position: Duration.zero,
    cacheProgress: Duration.zero,
  );
}
