// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtitle_track_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubtitleTrackDTO _$SubtitleTrackDTOFromJson(Map<String, dynamic> json) =>
    _SubtitleTrackDTO(
      trackEvents:
          (json['TrackEvents'] as List<dynamic>?)
              ?.map((e) => TrackEventDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SubtitleTrackDTOToJson(_SubtitleTrackDTO instance) =>
    <String, dynamic>{'TrackEvents': instance.trackEvents};

_TrackEventDTO _$TrackEventDTOFromJson(Map<String, dynamic> json) =>
    _TrackEventDTO(
      text: json['Text'] as String? ?? '',
      startPositionTicks: (json['StartPositionTicks'] as num?)?.toInt(),
      endPositionTicks: (json['EndPositionTicks'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TrackEventDTOToJson(_TrackEventDTO instance) =>
    <String, dynamic>{
      'Text': instance.text,
      'StartPositionTicks': instance.startPositionTicks,
      'EndPositionTicks': instance.endPositionTicks,
    };
