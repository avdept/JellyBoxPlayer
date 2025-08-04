import 'dart:convert';

import 'package:jplayer/src/data/dto/dto.dart';
import 'package:json_annotation/json_annotation.dart';

class SongUserDataConverter implements JsonConverter<SongUserData, String> {
  const SongUserDataConverter();

  @override
  SongUserData fromJson(String json) => SongUserData.fromJson(
    jsonDecode(json) as Map<String, dynamic>,
  );

  @override
  String toJson(SongUserData object) => jsonEncode(object.toJson());
}
