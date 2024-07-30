// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrappers_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AlbumsWrapperImpl _$$AlbumsWrapperImplFromJson(Map<String, dynamic> json) =>
    _$AlbumsWrapperImpl(
      items: (json['Items'] as List<dynamic>)
          .map((e) => ItemDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalRecordCount: (json['TotalRecordCount'] as num).toInt(),
    );

Map<String, dynamic> _$$AlbumsWrapperImplToJson(_$AlbumsWrapperImpl instance) =>
    <String, dynamic>{
      'Items': instance.items,
      'TotalRecordCount': instance.totalRecordCount,
    };
