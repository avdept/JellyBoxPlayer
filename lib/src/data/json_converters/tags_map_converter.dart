import 'package:json_annotation/json_annotation.dart';

class TagsMapConverter implements JsonConverter<Map<String, String>, String> {
  const TagsMapConverter();

  @override
  Map<String, String> fromJson(String json) => Map.unmodifiable(
    json.split(',').fold<Map<String, String>>(
      {},
      (map, tag) {
        final parts = tag.split(':');
        map[parts[0]] = parts[1];
        return map;
      },
    ),
  );

  @override
  String toJson(Map<String, String> object) =>
      object.entries.map((tag) => '${tag.key}:${tag.value}').join(',');
}
