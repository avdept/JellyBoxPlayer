import 'package:freezed_annotation/freezed_annotation.dart';

part 'playlist_data.freezed.dart';
part 'playlist_data.g.dart';

@Freezed(toJson: true)
abstract class PlaylistData with _$PlaylistData {
  const factory PlaylistData({
    @JsonKey(name: 'Name') required String name,
    @JsonKey(name: 'UserId') required String userId,
    @JsonKey(name: 'IsPublic') required bool isPublic,
  }) = _PlaylistData;

  factory PlaylistData.fromJson(Map<String, dynamic> json) =>
      _$PlaylistDataFromJson(json);
}
