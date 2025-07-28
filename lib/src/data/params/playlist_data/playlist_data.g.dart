// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaylistData _$PlaylistDataFromJson(Map<String, dynamic> json) =>
    _PlaylistData(
      name: json['Name'] as String,
      userId: json['UserId'] as String,
      isPublic: json['IsPublic'] as bool,
    );

Map<String, dynamic> _$PlaylistDataToJson(_PlaylistData instance) =>
    <String, dynamic>{
      'Name': instance.name,
      'UserId': instance.userId,
      'IsPublic': instance.isPublic,
    };
