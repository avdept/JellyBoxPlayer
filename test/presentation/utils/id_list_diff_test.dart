import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/presentation/utils/id_list_diff.dart';

void main() {
  group('diffIds', () {
    test('- reports nothing for identical lists', () {
      final diff = diffIds(['a', 'b', 'c'], ['a', 'b', 'c']);
      expect(diff.isEmpty, isTrue);
    });

    test('- new items at the front become ascending insertions', () {
      final diff = diffIds(['a', 'b', 'c'], ['x', 'y', 'a', 'b', 'c']);
      expect(diff.insertions, [0, 1]);
      expect(diff.removals, isEmpty);
    });

    test('- items pushed off the end become descending removals', () {
      final diff = diffIds(['a', 'b', 'c', 'd'], ['x', 'a', 'b']);
      expect(diff.insertions, [0]);
      expect(diff.removals, [3, 2]);
    });

    test('- an item moved to the front is a removal plus an insertion', () {
      final diff = diffIds(['a', 'b', 'c'], ['c', 'a', 'b']);
      expect(diff.insertions, [0]);
      expect(diff.removals, [2]);
    });

    test('- a full replacement lists every index', () {
      final diff = diffIds(['a', 'b'], ['x', 'y', 'z']);
      expect(diff.insertions, [0, 1, 2]);
      expect(diff.removals, [1, 0]);
    });
  });
}
