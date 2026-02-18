// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_stream_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaStreamDTO _$MediaStreamDTOFromJson(Map<String, dynamic> json) =>
    _MediaStreamDTO(
      type: json['Type'] as String?,
      codec: json['Codec'] as String?,
      bitRate: (json['BitRate'] as num?)?.toInt(),
      sampleRate: (json['SampleRate'] as num?)?.toInt(),
      bitDepth: (json['BitDepth'] as num?)?.toInt(),
      channels: (json['Channels'] as num?)?.toInt(),
      channelLayout: json['ChannelLayout'] as String?,
    );

Map<String, dynamic> _$MediaStreamDTOToJson(_MediaStreamDTO instance) =>
    <String, dynamic>{
      'Type': instance.type,
      'Codec': instance.codec,
      'BitRate': instance.bitRate,
      'SampleRate': instance.sampleRate,
      'BitDepth': instance.bitDepth,
      'Channels': instance.channels,
      'ChannelLayout': instance.channelLayout,
    };
