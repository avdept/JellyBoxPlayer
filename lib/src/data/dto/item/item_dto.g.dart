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
  'Album': instance.albumName,
  'AlbumArtist': instance.albumArtist,
  'AlbumArtists': instance.albumArtists,
  'BackdropImageTags': instance.backdropImageTags,
  'ImageTags': instance.imageTags,
  'UserData': instance.userData,
  'MediaSources': instance.mediaSources,
};

_DownloadedAlbumDTO _$DownloadedAlbumDTOFromJson(Map<String, dynamic> json) =>
    _DownloadedAlbumDTO(
      id: json['Id'] as String,
      name: json['Name'] as String,
      type: json['Type'] as String,
      runTimeTicks: (json['RunTimeTicks'] as num).toInt(),
      overview: json['Overview'] as String?,
      productionYear: (json['ProductionYear'] as num?)?.toInt(),
      albumArtist: json['AlbumArtist'] as String?,
      backdropImageTags: json['BackdropImageTags'] == null
          ? const []
          : const TagsListConverter().fromJson(
              json['BackdropImageTags'] as String,
            ),
      imageTags: json['ImageTags'] == null
          ? const {}
          : const TagsMapConverter().fromJson(json['ImageTags'] as String),
      downloadDate: _$JsonConverterFromJson<int, DateTime>(
        json['DownloadDate'],
        const EpochDateTimeConverter().fromJson,
      ),
      sizeInBytes: (json['SizeInBytes'] as num).toInt(),
    );

Map<String, dynamic> _$DownloadedAlbumDTOToJson(
  _DownloadedAlbumDTO instance,
) => <String, dynamic>{
  'Id': instance.id,
  'Name': instance.name,
  'Type': instance.type,
  'RunTimeTicks': instance.runTimeTicks,
  'Overview': instance.overview,
  'ProductionYear': instance.productionYear,
  'AlbumArtist': instance.albumArtist,
  'BackdropImageTags': const TagsListConverter().toJson(
    instance.backdropImageTags,
  ),
  'ImageTags': const TagsMapConverter().toJson(instance.imageTags),
  'DownloadDate': const EpochDateTimeConverter().toJson(instance.downloadDate),
  'SizeInBytes': instance.sizeInBytes,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

_DownloadedSongDTO _$DownloadedSongDTOFromJson(Map<String, dynamic> json) =>
    _DownloadedSongDTO(
      id: json['Id'] as String,
      name: json['Name'] as String,
      runTimeTicks: (json['RunTimeTicks'] as num).toInt(),
      indexNumber: (json['IndexNumber'] as num?)?.toInt() ?? 0,
      userData: const UserDataConverter().fromJson(json['UserData'] as String),
      type: json['Type'] as String,
      albumArtist: json['AlbumArtist'] as String?,
      playlistItemId: json['PlaylistItemId'] as String?,
      albumName: json['Album'] as String?,
      albumId: json['AlbumId'] as String?,
      imageTags: json['ImageTags'] == null
          ? const {}
          : const TagsMapConverter().fromJson(json['ImageTags'] as String),
      downloadDate: _$JsonConverterFromJson<int, DateTime>(
        json['DownloadDate'],
        const EpochDateTimeConverter().fromJson,
      ),
      filePath: json['FilePath'] as String,
      sizeInBytes: (json['SizeInBytes'] as num).toInt(),
    );

Map<String, dynamic> _$DownloadedSongDTOToJson(
  _DownloadedSongDTO instance,
) => <String, dynamic>{
  'Id': instance.id,
  'Name': instance.name,
  'Type': instance.type,
  'IndexNumber': instance.indexNumber,
  'RunTimeTicks': instance.runTimeTicks,
  'PlaylistItemId': instance.playlistItemId,
  'AlbumId': instance.albumId,
  'Album': instance.albumName,
  'AlbumArtist': instance.albumArtist,
  'UserData': const UserDataConverter().toJson(instance.userData),
  'ImageTags': const TagsMapConverter().toJson(instance.imageTags),
  'DownloadDate': const EpochDateTimeConverter().toJson(instance.downloadDate),
  'FilePath': instance.filePath,
  'SizeInBytes': instance.sizeInBytes,
};
