import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/letter_index.dart';
import 'package:jplayer/src/data/backend/library_query.dart';

void main() {
  const keys = ['#1', '1999', 'abba', 'air', 'beatles', 'zz top', 'ñu'];

  Future<LetterOffset> offset(String letter, SortDirection direction) =>
      letterOffsetInKeys(keys, letter: letter, direction: direction);

  group('letterOffsetInKeys ascending', () {
    test('- # starts the list', () async {
      expect(
        await offset('#', SortDirection.ascending),
        const LetterOffset(0, total: 7),
      );
    });

    test('- a letter starts after everything that sorts below it', () async {
      expect((await offset('A', SortDirection.ascending)).index, 2);
      expect((await offset('B', SortDirection.ascending)).index, 4);
      expect((await offset('C', SortDirection.ascending)).index, 5);
      expect((await offset('Z', SortDirection.ascending)).index, 5);
    });
  });

  group('letterOffsetInKeys descending', () {
    test('- a letter block starts where the next letter ends', () async {
      expect((await offset('A', SortDirection.descending)).index, 3);
      expect((await offset('B', SortDirection.descending)).index, 2);
    });

    test('- # comes last and non-latin names come first', () async {
      expect((await offset('#', SortDirection.descending)).index, 5);
      expect((await offset('Z', SortDirection.descending)).index, 1);
    });
  });

  group('letterOffsetWith', () {
    test('- ascending asks for one count and no total', () async {
      final bounds = <String>[];
      var totals = 0;
      final result = await letterOffsetWith(
        letter: 'M',
        direction: SortDirection.ascending,
        countBefore: (bound) async {
          bounds.add(bound);
          return 42;
        },
        total: () async {
          totals++;
          return 100;
        },
      );
      expect(result, const LetterOffset(42));
      expect(bounds, ['m']);
      expect(totals, 0);
    });

    test(
      '- descending subtracts the next letter count from the total',
      () async {
        final bounds = <String>[];
        final result = await letterOffsetWith(
          letter: 'M',
          direction: SortDirection.descending,
          countBefore: (bound) async {
            bounds.add(bound);
            return 60;
          },
          total: () async => 100,
        );
        expect(result, const LetterOffset(40, total: 100));
        expect(bounds, ['n']);
      },
    );
  });
}
