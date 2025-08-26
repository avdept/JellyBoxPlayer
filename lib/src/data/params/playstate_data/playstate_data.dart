import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/dto.dart';

part 'playstate_data.freezed.dart';
part 'playstate_data.g.dart';

@Freezed(toJson: true)
abstract class PlaystateData with _$PlaystateData {
  const factory PlaystateData({
    @JsonKey(name: 'PlaySessionId') required String playSessionId,
    @JsonKey(name: 'ItemId') required String itemId,
    @JsonKey(name: 'Item', includeIfNull: false) ItemDTO? item,
    @JsonKey(name: 'SessionId', includeIfNull: false) String? sessionId,
    @JsonKey(name: 'MediaSourceId', includeIfNull: false) String? mediaSourceId,
    @JsonKey(name: 'PositionTicks', includeIfNull: false) int? positionTicks,
  }) = _PlaystateData;
}
