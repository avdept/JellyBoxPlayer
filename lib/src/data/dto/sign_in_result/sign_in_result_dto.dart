import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/dto.dart';

part 'sign_in_result_dto.freezed.dart';
part 'sign_in_result_dto.g.dart';

@freezed
abstract class SignInResultDTO with _$SignInResultDTO {
  const factory SignInResultDTO({
    @JsonKey(name: 'User') required UserDTO user,
    @JsonKey(name: 'SessionInfo') required SessionInfoDTO sessionInfo,
    @JsonKey(name: 'AccessToken') required String accessToken,
    @JsonKey(name: 'ServerId') required String serverId,
  }) = _SignInResultDTO;

  factory SignInResultDTO.fromJson(Map<String, dynamic> json) =>
      _$SignInResultDTOFromJson(json);
}
