// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItemDTO _$ItemDTOFromJson(Map<String, dynamic> json) => _ItemDTO(
  id: json['Id'] as String,
  name: json['Name'] as String,
  serverId: json['ServerId'] as String,
  type: json['Type'] as String,
  overview: json['Overview'] as String?,
  durationInTicks: (json['RunTimeTicks'] as num?)?.toInt(),
  productionYear: (json['ProductionYear'] as num?)?.toInt(),
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
);

Map<String, dynamic> _$ItemDTOToJson(_ItemDTO instance) => <String, dynamic>{
  'Id': instance.id,
  'Name': instance.name,
  'ServerId': instance.serverId,
  'Type': instance.type,
  'Overview': instance.overview,
  'RunTimeTicks': instance.durationInTicks,
  'ProductionYear': instance.productionYear,
  'AlbumArtist': instance.albumArtist,
  'AlbumArtists': instance.albumArtists,
  'BackdropImageTags': instance.backdropImageTags,
  'ImageTags': instance.imageTags,
};

_DownloadedAlbumDTO _$DownloadedAlbumDTOFromJson(Map<String, dynamic> json) =>
    _DownloadedAlbumDTO(
      id: json['Id'] as String,
      name: json['Name'] as String,
      serverId: json['ServerId'] as String,
      type: json['Type'] as String,
      overview: json['Overview'] as String?,
      durationInTicks: (json['RunTimeTicks'] as num?)?.toInt(),
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
  'ServerId': instance.serverId,
  'Type': instance.type,
  'Overview': instance.overview,
  'RunTimeTicks': instance.durationInTicks,
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
