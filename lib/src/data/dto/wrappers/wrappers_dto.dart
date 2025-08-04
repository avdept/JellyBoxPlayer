import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';

part 'wrappers_dto.freezed.dart';
part 'wrappers_dto.g.dart';

@freezed
abstract class ItemsWrapper with _$ItemsWrapper {
  const factory ItemsWrapper({
    @JsonKey(name: 'Items') required List<ItemDTO> items,
    @JsonKey(name: 'TotalRecordCount') @Default(0) int totalRecordCount,
  }) = _ItemsWrapper;

  factory ItemsWrapper.fromJson(Map<String, dynamic> json) =>
      _$ItemsWrapperFromJson(json);
}
