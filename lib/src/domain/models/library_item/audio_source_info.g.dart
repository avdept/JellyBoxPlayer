// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_source_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AudioSourceInfo _$AudioSourceInfoFromJson(Map<String, dynamic> json) =>
    _AudioSourceInfo(
      id: json['id'] as String?,
      container: json['container'] as String?,
      codec: json['codec'] as String?,
      bitRate: (json['bitRate'] as num?)?.toInt(),
      sampleRate: (json['sampleRate'] as num?)?.toInt(),
      bitDepth: (json['bitDepth'] as num?)?.toInt(),
      channels: (json['channels'] as num?)?.toInt(),
      channelLayout: json['channelLayout'] as String?,
    );

Map<String, dynamic> _$AudioSourceInfoToJson(_AudioSourceInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'container': instance.container,
      'codec': instance.codec,
      'bitRate': instance.bitRate,
      'sampleRate': instance.sampleRate,
      'bitDepth': instance.bitDepth,
      'channels': instance.channels,
      'channelLayout': instance.channelLayout,
    };
