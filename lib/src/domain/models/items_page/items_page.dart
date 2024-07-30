import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';

part 'items_page.freezed.dart';

@freezed
class ItemsPage with _$ItemsPage {
  const factory ItemsPage({
    @Default([]) List<ItemDTO> items,
    @Default(0) int currentPage,
    @Default(100) int totalPerPage,
  }) = _ItemsPage;
}
