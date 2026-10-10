import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  List<LibraryItem> items(int start, int count) => [
    for (var i = start; i < start + count; i++)
      LibraryItem(id: 'item-$i', name: 'Item $i', kind: ItemKind.album),
  ];

  group('PagedItems.withPage', () {
    test('- adopts a server total that reaches past the page', () {
      final page = const PagedItems(pageSize: 10).withPage(
        0,
        items(0, 10),
        isLastPage: false,
        totalCount: 35,
      );
      expect(page.totalCount, 35);
      expect(page.length, 35);
      expect(page.nextPage, 1);
    });

    test('- a short page closes the list at its end', () {
      final page = const PagedItems(pageSize: 10).withPage(
        2,
        items(20, 4),
        isLastPage: true,
        totalCount: 24,
      );
      expect(page.totalCount, 24);
      expect(page.length, 24);
    });

    test('- an open-ended full page leaves the total unknown', () {
      final page = const PagedItems(pageSize: 10).withPage(
        0,
        items(0, 10),
        isLastPage: false,
        totalCount: 10,
      );
      expect(page.totalCount, isNull);
      expect(page.length, 10);
      expect(page.nextPage, 1);
    });

    test('- a full page never shrinks a known total', () {
      final page = const PagedItems(pageSize: 10, totalCount: 50).withPage(
        3,
        items(30, 10),
        isLastPage: false,
        totalCount: 40,
      );
      expect(page.totalCount, 50);
    });
  });

  group('PagedItems lookup', () {
    final sparse = const PagedItems(pageSize: 10, totalCount: 40)
        .withPage(0, items(0, 10), isLastPage: false, totalCount: 40)
        .withPage(3, items(30, 10), isLastPage: false, totalCount: 40);

    test('- itemAt resolves loaded indexes and nothing else', () {
      expect(sparse.itemAt(7)?.id, 'item-7');
      expect(sparse.itemAt(35)?.id, 'item-35');
      expect(sparse.itemAt(15), isNull);
    });

    test('- nextPage follows the furthest loaded page', () {
      expect(sparse.nextPage, isNull);
      expect(
        const PagedItems(pageSize: 10, totalCount: 40)
            .withPage(1, items(10, 10), isLastPage: false, totalCount: 40)
            .nextPage,
        2,
      );
    });

    test('- items are flattened in index order', () {
      expect(sparse.items.map((item) => item.id).take(11).last, 'item-30');
      expect(sparse.items.length, 20);
    });
  });

  group('PagedItems.keepPagesAround', () {
    test('- drops the pages farthest from the focus', () {
      var paged = const PagedItems(pageSize: 10, totalCount: 100);
      for (var page = 0; page < 10; page++) {
        paged = paged.withPage(
          page,
          items(page * 10, 10),
          isLastPage: false,
          totalCount: 100,
        );
      }
      final kept = paged.keepPagesAround(8, keep: 4);
      expect(kept.pages.keys.toList()..sort(), [6, 7, 8, 9]);
      expect(kept.totalCount, 100);
      expect(kept.length, 100);
    });

    test('- leaves a list within the window alone', () {
      final paged = const PagedItems(
        pageSize: 10,
      ).withPage(0, items(0, 10), isLastPage: false, totalCount: 10);
      expect(identical(paged.keepPagesAround(0, keep: 3), paged), isTrue);
    });
  });

  test('PagedItems.of chunks a full list into pages', () {
    final paged = PagedItems.of(items(0, 23), pageSize: 10);
    expect(paged.totalCount, 23);
    expect(paged.pages.keys.toList()..sort(), [0, 1, 2]);
    expect(paged.itemAt(22)?.id, 'item-22');
    expect(paged.nextPage, isNull);
  });
}
