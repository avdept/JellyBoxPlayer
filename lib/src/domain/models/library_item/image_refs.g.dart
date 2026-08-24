// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_refs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ImageRefs _$ImageRefsFromJson(Map<String, dynamic> json) => _ImageRefs(
  primary: json['primary'] as String?,
  primaryItemId: json['primaryItemId'] as String?,
  albumPrimary: json['albumPrimary'] as String?,
  backdrops:
      (json['backdrops'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ImageRefsToJson(_ImageRefs instance) =>
    <String, dynamic>{
      'primary': instance.primary,
      'primaryItemId': instance.primaryItemId,
      'albumPrimary': instance.albumPrimary,
      'backdrops': instance.backdrops,
    };
