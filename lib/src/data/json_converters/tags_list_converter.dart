import 'package:json_annotation/json_annotation.dart';

class TagsListConverter implements JsonConverter<List<String>, String> {
  const TagsListConverter();

  @override
  List<String> fromJson(String json) => List.unmodifiable(json.split(','));

  @override
  String toJson(List<String> object) => object.join(',');
}
