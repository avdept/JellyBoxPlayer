// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlaybackUserData _$PlaybackUserDataFromJson(Map<String, dynamic> json) =>
    _PlaybackUserData(
      position: json['position'] == null
          ? Duration.zero
          : const DurationMillisConverter().fromJson(
              (json['position'] as num).toInt(),
            ),
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      played: json['played'] as bool? ?? false,
    );

Map<String, dynamic> _$PlaybackUserDataToJson(_PlaybackUserData instance) =>
    <String, dynamic>{
      'position': const DurationMillisConverter().toJson(instance.position),
      'playCount': instance.playCount,
      'isFavorite': instance.isFavorite,
      'played': instance.played,
    };
