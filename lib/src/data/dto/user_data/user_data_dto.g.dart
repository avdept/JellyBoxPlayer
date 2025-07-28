// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserData _$UserDataFromJson(Map<String, dynamic> json) => _UserData(
  playbackPositionTicks: (json['PlaybackPositionTicks'] as num?)?.toInt() ?? 0,
  playCount: (json['PlayCount'] as num?)?.toInt() ?? 0,
  isFavorite: json['IsFavorite'] as bool? ?? false,
  played: json['Played'] as bool? ?? false,
);

Map<String, dynamic> _$UserDataToJson(_UserData instance) => <String, dynamic>{
  'PlaybackPositionTicks': instance.playbackPositionTicks,
  'PlayCount': instance.playCount,
  'IsFavorite': instance.isFavorite,
  'Played': instance.played,
};
