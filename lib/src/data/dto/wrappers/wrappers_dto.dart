import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';

part 'wrappers_dto.freezed.dart';
part 'wrappers_dto.g.dart';


@freezed
class AlbumsWrapper with _$AlbumsWrapper {
  const factory AlbumsWrapper({@JsonKey(name: 'Items') required List<ItemDTO> items, @JsonKey(name: 'TotalRecordCount') required int totalRecordCount}) = _AlbumsWrapper;

  factory AlbumsWrapper.fromJson(Map<String, dynamic> json) => _$AlbumsWrapperFromJson(json);
}
