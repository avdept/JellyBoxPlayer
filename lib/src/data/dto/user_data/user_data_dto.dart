import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_data_dto.freezed.dart';
part 'user_data_dto.g.dart';

@freezed
abstract class UserData with _$UserData {
  const factory UserData({
    @JsonKey(name: 'PlaybackPositionTicks') @Default(0) int playbackPositionTicks,
    @JsonKey(name: 'PlayCount') @Default(0) int playCount,
    @JsonKey(name: 'IsFavorite') @Default(false) bool isFavorite,
    @JsonKey(name: 'Played') @Default(false) bool played,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}
