import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
abstract class UserDTO with _$UserDTO {
  const factory UserDTO({
    @JsonKey(name: 'Id') required String id,
    @JsonKey(name: 'Name') String? name,
  }) = _UserDTO;

  factory UserDTO.fromJson(Map<String, dynamic> json) =>
      _$UserDTOFromJson(json);
}
