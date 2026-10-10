import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/domain/models/library_item/library_item.dart';

part 'paged_items.freezed.dart';

@freezed
abstract class PagedItems with _$PagedItems {
  const factory PagedItems({
    @Default({}) Map<int, List<LibraryItem>> pages,
    int? totalCount,
    @Default(100) int pageSize,
  }) = _PagedItems;

  const PagedItems._();

  factory PagedItems.of(List<LibraryItem> items, {int pageSize = 100}) =>
      PagedItems(
        pages: {
          for (var start = 0; start < items.length; start += pageSize)
            start ~/ pageSize: items.sublist(
              start,
              min(start + pageSize, items.length),
            ),
        },
        totalCount: items.length,
        pageSize: pageSize,
      );

  int get loadedEnd => pages.entries.fold(
    0,
    (end, entry) => max(end, entry.key * pageSize + entry.value.length),
  );

  int get length => totalCount ?? loadedEnd;

  bool get isEmpty => length == 0;

  int get pageCount => (length + pageSize - 1) ~/ pageSize;

  bool hasPage(int page) => pages.containsKey(page);

  int? get nextPage {
    final page = pages.isEmpty ? 0 : pages.keys.reduce(max) + 1;
    if (totalCount != null && page >= pageCount) return null;
    return page;
  }

  LibraryItem? itemAt(int index) =>
      pages[index ~/ pageSize]?.elementAtOrNull(index % pageSize);

  List<LibraryItem> get items => [
    for (final page in pages.keys.toList()..sort()) ...pages[page]!,
  ];

  PagedItems withPage(
    int page,
    List<LibraryItem> items, {
    required bool isLastPage,
    int? totalCount,
  }) {
    final end = page * pageSize + items.length;
    return copyWith(
      pages: {...pages, page: items},
      totalCount: isLastPage
          ? end
          : (totalCount != null && totalCount > end
                ? totalCount
                : this.totalCount),
    );
  }

  PagedItems keepPagesAround(int focusPage, {required int keep}) {
    if (pages.length <= keep) return this;
    final kept = pages.keys.toList()
      ..sort(
        (a, b) => (a - focusPage).abs().compareTo((b - focusPage).abs()),
      );
    return copyWith(
      pages: {for (final page in kept.take(keep)) page: pages[page]!},
    );
  }

  PagedItems mapItems(LibraryItem Function(LibraryItem item) transform) =>
      copyWith(
        pages: {
          for (final entry in pages.entries)
            entry.key: [for (final item in entry.value) transform(item)],
        },
      );
}
