import 'package:freezed_annotation/freezed_annotation.dart';

part 'quick_connect_state_dto.freezed.dart';
part 'quick_connect_state_dto.g.dart';

@freezed
abstract class QuickConnectStateDTO with _$QuickConnectStateDTO {
  const factory QuickConnectStateDTO({
    @JsonKey(name: 'Secret') required String secret,
    @JsonKey(name: 'Code') required String code,
    @JsonKey(name: 'Authenticated') @Default(false) bool authenticated,
  }) = _QuickConnectStateDTO;

  factory QuickConnectStateDTO.fromJson(Map<String, dynamic> json) =>
      _$QuickConnectStateDTOFromJson(json);
}
