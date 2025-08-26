// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_info_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionInfoDTO _$SessionInfoDTOFromJson(Map<String, dynamic> json) =>
    _SessionInfoDTO(
      id: json['Id'] as String,
      playState: json['PlayState'] as Map<String, dynamic>,
      nowPlayingItem: json['NowPlayingItem'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SessionInfoDTOToJson(_SessionInfoDTO instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'PlayState': instance.playState,
      'NowPlayingItem': instance.nowPlayingItem,
    };
