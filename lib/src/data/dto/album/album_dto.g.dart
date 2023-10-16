// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_AlbumDTO _$$_AlbumDTOFromJson(Map<String, dynamic> json) => _$_AlbumDTO(
      id: json['Id'] as String,
      name: json['Name'] as String,
      albumArtist: json['AlbumArtist'] as String,
      imageTags: (json['ImageTags'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$_AlbumDTOToJson(_$_AlbumDTO instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'Name': instance.name,
      'AlbumArtist': instance.albumArtist,
      'ImageTags': instance.imageTags,
    };

_$_AlbumsWrapper _$$_AlbumsWrapperFromJson(Map<String, dynamic> json) =>
    _$_AlbumsWrapper(
      items: (json['Items'] as List<dynamic>)
          .map((e) => AlbumDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$_AlbumsWrapperToJson(_$_AlbumsWrapper instance) =>
    <String, dynamic>{
      'Items': instance.items,
    };
