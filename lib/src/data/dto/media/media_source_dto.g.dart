// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_source_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaSourceDTO _$MediaSourceDTOFromJson(Map<String, dynamic> json) =>
    _MediaSourceDTO(
      container: json['Container'] as String?,
      mediaStreams:
          (json['MediaStreams'] as List<dynamic>?)
              ?.map((e) => MediaStreamDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MediaSourceDTOToJson(_MediaSourceDTO instance) =>
    <String, dynamic>{
      'Container': instance.container,
      'MediaStreams': instance.mediaStreams,
    };
