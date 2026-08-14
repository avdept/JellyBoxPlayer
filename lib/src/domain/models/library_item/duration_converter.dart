import 'package:json_annotation/json_annotation.dart';

class DurationMillisConverter implements JsonConverter<Duration, int> {
  const DurationMillisConverter();

  @override
  Duration fromJson(int json) => Duration(milliseconds: json);

  @override
  int toJson(Duration object) => object.inMilliseconds;
}
