// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'songs_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongDTOImpl _$$SongDTOImplFromJson(Map<String, dynamic> json) =>
    _$SongDTOImpl(
      id: json['Id'] as String,
      runTimeTicks: (json['RunTimeTicks'] as num).toInt(),
      indexNumber: (json['IndexNumber'] as num?)?.toInt() ?? 0,
      songUserData:
          SongUserData.fromJson(json['UserData'] as Map<String, dynamic>),
      type: json['Type'] as String,
      albumArtist: json['AlbumArtist'] as String?,
      albumArtists: (json['AlbumArtists'] as List<dynamic>?)
          ?.map((e) => ArtistDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      albumName: json['Album'] as String?,
      albumId: json['AlbumId'] as String?,
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
      'AlbumArtists': instance.albumArtists,
      'Album': instance.albumName,
      'AlbumId': instance.albumId,
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
      playbackPositionTicks: (json['PlaybackPositionTicks'] as num).toInt(),
      playCount: (json['PlayCount'] as num).toInt(),
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
