// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LyricsDTO _$LyricsDTOFromJson(Map<String, dynamic> json) => _LyricsDTO(
  metadata: json['Metadata'] == null
      ? const LyricMetadataDTO()
      : LyricMetadataDTO.fromJson(json['Metadata'] as Map<String, dynamic>),
  lyrics:
      (json['Lyrics'] as List<dynamic>?)
          ?.map((e) => LyricLineDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$LyricsDTOToJson(_LyricsDTO instance) =>
    <String, dynamic>{'Metadata': instance.metadata, 'Lyrics': instance.lyrics};

_LyricLineDTO _$LyricLineDTOFromJson(Map<String, dynamic> json) =>
    _LyricLineDTO(
      text: json['Text'] as String? ?? '',
      start: (json['Start'] as num?)?.toInt(),
      cues: (json['Cues'] as List<dynamic>?)
          ?.map((e) => LyricLineCueDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LyricLineDTOToJson(_LyricLineDTO instance) =>
    <String, dynamic>{
      'Text': instance.text,
      'Start': instance.start,
      'Cues': instance.cues,
    };

_LyricLineCueDTO _$LyricLineCueDTOFromJson(Map<String, dynamic> json) =>
    _LyricLineCueDTO(
      position: (json['Position'] as num?)?.toInt() ?? 0,
      endPosition: (json['EndPosition'] as num?)?.toInt() ?? 0,
      start: (json['Start'] as num?)?.toInt() ?? 0,
      end: (json['End'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LyricLineCueDTOToJson(_LyricLineCueDTO instance) =>
    <String, dynamic>{
      'Position': instance.position,
      'EndPosition': instance.endPosition,
      'Start': instance.start,
      'End': instance.end,
    };

_LyricMetadataDTO _$LyricMetadataDTOFromJson(Map<String, dynamic> json) =>
    _LyricMetadataDTO(
      artist: json['Artist'] as String?,
      album: json['Album'] as String?,
      title: json['Title'] as String?,
      author: json['Author'] as String?,
      length: (json['Length'] as num?)?.toInt(),
      by: json['By'] as String?,
      offset: (json['Offset'] as num?)?.toInt(),
      creator: json['Creator'] as String?,
      version: json['Version'] as String?,
      isSynced: json['IsSynced'] as bool?,
    );

Map<String, dynamic> _$LyricMetadataDTOToJson(_LyricMetadataDTO instance) =>
    <String, dynamic>{
      'Artist': instance.artist,
      'Album': instance.album,
      'Title': instance.title,
      'Author': instance.author,
      'Length': instance.length,
      'By': instance.by,
      'Offset': instance.offset,
      'Creator': instance.creator,
      'Version': instance.version,
      'IsSynced': instance.isSynced,
    };
