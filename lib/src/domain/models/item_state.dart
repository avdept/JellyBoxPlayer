import 'package:jplayer/src/data/dto/item/item_dto.dart';

class ItemState {
  ItemState({this.items = const [], this.currentPage = 0, this.totalPerPage = 100});
  List<ItemDTO> items = [];
  int currentPage = 0;
  int totalPerPage = 100;

  ItemState copyWith({List<ItemDTO> items = const [], int currentPage = 0, int totalPerPage = 100}) {
    return ItemState(items: items, currentPage: currentPage, totalPerPage: totalPerPage);
  }
}
