// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_connect_state_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuickConnectStateDTO _$QuickConnectStateDTOFromJson(
  Map<String, dynamic> json,
) => _QuickConnectStateDTO(
  secret: json['Secret'] as String,
  code: json['Code'] as String,
  authenticated: json['Authenticated'] as bool? ?? false,
);

Map<String, dynamic> _$QuickConnectStateDTOToJson(
  _QuickConnectStateDTO instance,
) => <String, dynamic>{
  'Secret': instance.secret,
  'Code': instance.code,
  'Authenticated': instance.authenticated,
};
