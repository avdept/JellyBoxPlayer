// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrappers_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItemsWrapper _$ItemsWrapperFromJson(Map<String, dynamic> json) =>
    _ItemsWrapper(
      items: (json['Items'] as List<dynamic>)
          .map((e) => ItemDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRecordCount: (json['TotalRecordCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ItemsWrapperToJson(_ItemsWrapper instance) =>
    <String, dynamic>{
      'Items': instance.items,
      'TotalRecordCount': instance.totalRecordCount,
    };
