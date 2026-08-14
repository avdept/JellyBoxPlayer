import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/library_item/library_item.dart';

export 'package:jplayer/src/core/enums/enums.dart' show PlaybackStatus;

part 'playback_state.freezed.dart';

@freezed
abstract class PlaybackState with _$PlaybackState {
  const factory PlaybackState({
    required LibraryItem? album,
    required List<LibraryItem> songs,
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
