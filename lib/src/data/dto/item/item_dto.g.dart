// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_ItemDTO _$$_ItemDTOFromJson(Map<String, dynamic> json) => _$_ItemDTO(
      id: json['Id'] as String,
      name: json['Name'] as String,
      serverId: json['ServerId'] as String,
      durationInTicks: json['RunTimeTicks'] as int,
      productionYear: json['ProductionYear'] as int?,
      albumArtist: json['AlbumArtist'] as String?,
      imageTags: (json['ImageTags'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$_ItemDTOToJson(_$_ItemDTO instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'Name': instance.name,
      'ServerId': instance.serverId,
      'RunTimeTicks': instance.durationInTicks,
      'ProductionYear': instance.productionYear,
      'AlbumArtist': instance.albumArtist,
      'ImageTags': instance.imageTags,
    };
