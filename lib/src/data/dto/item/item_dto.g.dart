// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItemDTO _$ItemDTOFromJson(Map<String, dynamic> json) => _ItemDTO(
  id: json['Id'] as String,
  name: json['Name'] as String,
  type: json['Type'] as String,
  indexNumber: (json['IndexNumber'] as num?)?.toInt() ?? 0,
  runTimeTicks: (json['RunTimeTicks'] as num?)?.toInt() ?? 0,
  path: json['Path'] as String?,
  collectionType: json['CollectionType'] as String?,
  playlistItemId: json['PlaylistItemId'] as String?,
  overview: json['Overview'] as String?,
  productionYear: (json['ProductionYear'] as num?)?.toInt(),
  albumId: json['AlbumId'] as String?,
  albumPrimaryImageTag: json['AlbumPrimaryImageTag'] as String?,
  albumName: json['Album'] as String?,
  albumArtist: json['AlbumArtist'] as String?,
  albumArtists:
      (json['AlbumArtists'] as List<dynamic>?)
          ?.map((e) => ArtistDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  backdropImageTags:
      (json['BackdropImageTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  imageTags:
      (json['ImageTags'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  hasLyrics: json['HasLyrics'] as bool? ?? false,
  userData: json['UserData'] == null
      ? const UserData()
      : UserData.fromJson(json['UserData'] as Map<String, dynamic>),
  mediaSources:
      (json['MediaSources'] as List<dynamic>?)
          ?.map((e) => MediaSourceDTO.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ItemDTOToJson(_ItemDTO instance) => <String, dynamic>{
  'Id': instance.id,
  'Name': instance.name,
  'Type': instance.type,
  'IndexNumber': instance.indexNumber,
  'RunTimeTicks': instance.runTimeTicks,
  'Path': instance.path,
  'CollectionType': instance.collectionType,
  'PlaylistItemId': instance.playlistItemId,
  'Overview': instance.overview,
  'ProductionYear': instance.productionYear,
  'AlbumId': instance.albumId,
  'AlbumPrimaryImageTag': instance.albumPrimaryImageTag,
  'Album': instance.albumName,
  'AlbumArtist': instance.albumArtist,
  'AlbumArtists': instance.albumArtists,
  'BackdropImageTags': instance.backdropImageTags,
  'ImageTags': instance.imageTags,
  'HasLyrics': instance.hasLyrics,
  'UserData': instance.userData,
  'MediaSources': instance.mediaSources,
};
