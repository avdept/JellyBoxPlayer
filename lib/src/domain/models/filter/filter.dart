import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/core/enums/enums.dart';

part 'filter.freezed.dart';

@freezed
class Filter with _$Filter {
  const factory Filter({
    required Entities orderBy,
    @Default(false) bool desc,
  }) = _Filter;
}
