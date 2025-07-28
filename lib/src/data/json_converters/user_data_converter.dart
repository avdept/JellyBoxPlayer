import 'dart:convert';

import 'package:jplayer/src/data/dto/dto.dart';
import 'package:json_annotation/json_annotation.dart';

class UserDataConverter implements JsonConverter<UserData, String> {
  const UserDataConverter();

  @override
  UserData fromJson(String json) => UserData.fromJson(
    jsonDecode(json) as Map<String, dynamic>,
  );

  @override
  String toJson(UserData object) => jsonEncode(object.toJson());
}
