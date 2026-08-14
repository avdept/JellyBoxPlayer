import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/domain/models/library_item/duration_converter.dart';

part 'playback_user_data.freezed.dart';
part 'playback_user_data.g.dart';

@freezed
abstract class PlaybackUserData with _$PlaybackUserData {
  const factory PlaybackUserData({
    @DurationMillisConverter() @Default(Duration.zero) Duration position,
    @Default(0) int playCount,
    @Default(false) bool isFavorite,
    @Default(false) bool played,
  }) = _PlaybackUserData;

  factory PlaybackUserData.fromJson(Map<String, dynamic> json) =>
      _$PlaybackUserDataFromJson(json);
}
