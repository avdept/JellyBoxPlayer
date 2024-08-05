// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemDTOImpl _$$ItemDTOImplFromJson(Map<String, dynamic> json) =>
    _$ItemDTOImpl(
      id: json['Id'] as String,
      name: json['Name'] as String,
      serverId: json['ServerId'] as String,
      type: json['Type'] as String,
      durationInTicks: (json['RunTimeTicks'] as num?)?.toInt(),
      overview: json['Overview'] as String?,
      productionYear: (json['ProductionYear'] as num?)?.toInt(),
      albumArtist: json['AlbumArtist'] as String?,
      backgropImageTags: (json['BackdropImageTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      imageTags: (json['ImageTags'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ItemDTOImplToJson(_$ItemDTOImpl instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'Name': instance.name,
      'ServerId': instance.serverId,
      'Type': instance.type,
      'RunTimeTicks': instance.durationInTicks,
      'Overview': instance.overview,
      'ProductionYear': instance.productionYear,
      'AlbumArtist': instance.albumArtist,
      'BackdropImageTags': instance.backgropImageTags,
      'ImageTags': instance.imageTags,
    };
