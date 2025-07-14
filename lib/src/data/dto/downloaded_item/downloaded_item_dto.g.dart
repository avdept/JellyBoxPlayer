// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloaded_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadedItemDTO _$DownloadedItemDTOFromJson(Map<String, dynamic> json) =>
    _DownloadedItemDTO(
      id: json['id'] as String,
      name: json['name'] as String?,
      albumId: json['albumId'] as String?,
      albumName: json['albumName'] as String?,
      artistName: json['artistName'] as String?,
      downloadDate: DateTime.parse(json['downloadDate'] as String),
      filePath: json['filePath'] as String,
      sizeInBytes: (json['sizeInBytes'] as num).toInt(),
    );

Map<String, dynamic> _$DownloadedItemDTOToJson(_DownloadedItemDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'albumId': instance.albumId,
      'albumName': instance.albumName,
      'artistName': instance.artistName,
      'downloadDate': instance.downloadDate.toIso8601String(),
      'filePath': instance.filePath,
      'sizeInBytes': instance.sizeInBytes,
    };
