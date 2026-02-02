// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SignInResultDTO _$SignInResultDTOFromJson(Map<String, dynamic> json) =>
    _SignInResultDTO(
      user: UserDTO.fromJson(json['User'] as Map<String, dynamic>),
      sessionInfo: SessionInfoDTO.fromJson(
        json['SessionInfo'] as Map<String, dynamic>,
      ),
      accessToken: json['AccessToken'] as String,
      serverId: json['ServerId'] as String,
    );

Map<String, dynamic> _$SignInResultDTOToJson(_SignInResultDTO instance) =>
    <String, dynamic>{
      'User': instance.user,
      'SessionInfo': instance.sessionInfo,
      'AccessToken': instance.accessToken,
      'ServerId': instance.serverId,
    };
