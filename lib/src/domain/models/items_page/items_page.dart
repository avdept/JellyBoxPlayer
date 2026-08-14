import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/domain/models/library_item/library_item.dart';

part 'items_page.freezed.dart';

@freezed
abstract class ItemsPage with _$ItemsPage {
  const factory ItemsPage({
    @Default([]) List<LibraryItem> items,
    @Default(0) int currentPage,
    @Default(100) int totalPerPage,
  }) = _ItemsPage;
}
