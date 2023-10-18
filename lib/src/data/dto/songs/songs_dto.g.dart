// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'songs_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_SongDTO _$$_SongDTOFromJson(Map<String, dynamic> json) => _$_SongDTO(
      id: json['Id'] as String,
      name: json['Name'] as String,
      albumName: json['Album'] as String,
      albumArtist: json['AlbumArtist'] as String,
      imageTags: (json['ImageTags'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$_SongDTOToJson(_$_SongDTO instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'Name': instance.name,
      'Album': instance.albumName,
      'AlbumArtist': instance.albumArtist,
      'ImageTags': instance.imageTags,
    };

_$_SongsWrapper _$$_SongsWrapperFromJson(Map<String, dynamic> json) =>
    _$_SongsWrapper(
      items: (json['Items'] as List<dynamic>)
          .map((e) => SongDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$_SongsWrapperToJson(_$_SongsWrapper instance) =>
    <String, dynamic>{
      'Items': instance.items,
    };
