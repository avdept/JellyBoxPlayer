import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_info_dto.freezed.dart';
part 'session_info_dto.g.dart';

@freezed
abstract class SessionInfoDTO with _$SessionInfoDTO {
  const factory SessionInfoDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'PlayState') required Map<String, dynamic> playState,
    @JsonKey(name: 'NowPlayingItem') Map<String, dynamic>? nowPlayingItem,
  }) = _SessionInfoDTO;

  factory SessionInfoDTO.fromJson(Map<String, dynamic> json) =>
      _$SessionInfoDTOFromJson(json);
}
