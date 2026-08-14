import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/domain/models/library_item/library_item.dart';

part 'library_page.freezed.dart';

@freezed
abstract class LibraryPage with _$LibraryPage {
  const factory LibraryPage({
    @Default([]) List<LibraryItem> items,
    @Default(0) int totalRecordCount,
  }) = _LibraryPage;
}
