// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrappers_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AlbumsWrapper _$AlbumsWrapperFromJson(Map<String, dynamic> json) =>
    _AlbumsWrapper(
      items: (json['Items'] as List<dynamic>)
          .map((e) => ItemDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRecordCount: (json['TotalRecordCount'] as num).toInt(),
    );

Map<String, dynamic> _$AlbumsWrapperToJson(_AlbumsWrapper instance) =>
    <String, dynamic>{
      'Items': instance.items,
      'TotalRecordCount': instance.totalRecordCount,
    };
