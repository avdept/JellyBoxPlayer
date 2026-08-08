import 'package:freezed_annotation/freezed_annotation.dart';

part 'playstate_data.freezed.dart';
part 'playstate_data.g.dart';

@Freezed(toJson: true)
abstract class PlaystateData with _$PlaystateData {
  const factory PlaystateData({
    @JsonKey(name: 'PlaySessionId') required String playSessionId,
    @JsonKey(name: 'ItemId') required String itemId,
    @JsonKey(name: 'SessionId', includeIfNull: false) String? sessionId,
    @JsonKey(name: 'MediaSourceId', includeIfNull: false) String? mediaSourceId,
    @JsonKey(name: 'PositionTicks', includeIfNull: false) int? positionTicks,
    @JsonKey(name: 'IsPaused', includeIfNull: false) bool? isPaused,
    @JsonKey(name: 'CanSeek', includeIfNull: false) bool? canSeek,
    @JsonKey(name: 'NowPlayingQueue', includeIfNull: false)
    List<QueueItemData>? nowPlayingQueue,
  }) = _PlaystateData;
}

@Freezed(toJson: true)
abstract class QueueItemData with _$QueueItemData {
  const factory QueueItemData({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'PlaylistItemId', includeIfNull: false)
    String? playlistItemId,
  }) = _QueueItemData;
}
