// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloaded_album_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadedAlbumDTO _$DownloadedAlbumDTOFromJson(Map<String, dynamic> json) =>
    _DownloadedAlbumDTO(
      id: json['id'] as String,
      name: json['name'] as String,
      artistName: json['artistName'] as String?,
      imageTags: Map<String, String>.from(json['imageTags'] as Map),
      downloadDate: DateTime.parse(json['downloadDate'] as String),
      sizeInBytes: (json['sizeInBytes'] as num).toInt(),
    );

Map<String, dynamic> _$DownloadedAlbumDTOToJson(_DownloadedAlbumDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'artistName': instance.artistName,
      'imageTags': instance.imageTags,
      'downloadDate': instance.downloadDate.toIso8601String(),
      'sizeInBytes': instance.sizeInBytes,
    };
