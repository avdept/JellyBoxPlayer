// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'songs_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongDTOImpl _$$SongDTOImplFromJson(Map<String, dynamic> json) =>
    _$SongDTOImpl(
      id: json['Id'] as String,
      runTimeTicks: json['RunTimeTicks'] as int,
      indexNumber: json['IndexNumber'] as int,
      songUserData:
          SongUserData.fromJson(json['UserData'] as Map<String, dynamic>),
      type: json['Type'] as String,
      albumArtist: json['AlbumArtist'] as String?,
      albumName: json['Album'] as String?,
      name: json['Name'] as String?,
      imageTags: (json['ImageTags'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$SongDTOImplToJson(_$SongDTOImpl instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'RunTimeTicks': instance.runTimeTicks,
      'IndexNumber': instance.indexNumber,
      'UserData': instance.songUserData,
      'Type': instance.type,
      'AlbumArtist': instance.albumArtist,
      'Album': instance.albumName,
      'Name': instance.name,
      'ImageTags': instance.imageTags,
    };

_$SongsWrapperImpl _$$SongsWrapperImplFromJson(Map<String, dynamic> json) =>
    _$SongsWrapperImpl(
      items: (json['Items'] as List<dynamic>)
          .map((e) => SongDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$SongsWrapperImplToJson(_$SongsWrapperImpl instance) =>
    <String, dynamic>{
      'Items': instance.items,
    };

_$SongUserDataImpl _$$SongUserDataImplFromJson(Map<String, dynamic> json) =>
    _$SongUserDataImpl(
      playbackPositionTicks: json['PlaybackPositionTicks'] as int,
      playCount: json['PlayCount'] as int,
      isFavorite: json['IsFavorite'] as bool,
      played: json['Played'] as bool,
    );

Map<String, dynamic> _$$SongUserDataImplToJson(_$SongUserDataImpl instance) =>
    <String, dynamic>{
      'PlaybackPositionTicks': instance.playbackPositionTicks,
      'PlayCount': instance.playCount,
      'IsFavorite': instance.isFavorite,
      'Played': instance.played,
    };
