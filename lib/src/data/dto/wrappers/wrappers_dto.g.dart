// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrappers_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_AlbumsWrapper _$$_AlbumsWrapperFromJson(Map<String, dynamic> json) =>
    _$_AlbumsWrapper(
      items: (json['Items'] as List<dynamic>)
          .map((e) => ItemDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRecordCount: json['TotalRecordCount'] as int,
    );

Map<String, dynamic> _$$_AlbumsWrapperToJson(_$_AlbumsWrapper instance) =>
    <String, dynamic>{
      'Items': instance.items,
      'TotalRecordCount': instance.totalRecordCount,
    };
