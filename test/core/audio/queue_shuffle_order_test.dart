import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/queue_shuffle_order.dart';

void main() {
  QueueShuffleOrder orderOf(List<int> indices) {
    final order = QueueShuffleOrder(random: Random(7));
    order.indices.addAll(indices);
    return order;
  }

  group('QueueShuffleOrder', () {
    test('places an insert right after the playing item when asked', () {
      final order = orderOf([2, 0, 1]);

      order.nextInsertPosition = order.positionAfterIndex(0);
      order.insert(3, 1);

      expect(order.indices, [2, 0, 3, 1]);
    });

    test('places an insert last when asked for the end of the queue', () {
      final order = orderOf([2, 0, 1]);

      order.nextInsertPosition = order.lastPosition;
      order.insert(3, 1);

      expect(order.indices, [2, 0, 1, 3]);
    });

    test('shifts existing indices at or above the insertion point', () {
      final order = orderOf([2, 0, 1]);

      order.nextInsertPosition = 0;
      order.insert(1, 1);

      expect(order.indices, [1, 3, 0, 2]);
    });

    test('falls back to a random position once the request is spent', () {
      final order = orderOf([0, 1]);

      order.nextInsertPosition = 0;
      order.insert(2, 1);
      expect(order.indices.first, 2);
      expect(order.nextInsertPosition, isNull);

      order.insert(3, 1);
      expect(order.indices, containsAll([0, 1, 2, 3]));
      expect(order.indices, hasLength(4));
    });

    test('keeps the requested item first when shuffling', () {
      final order = orderOf([0, 1, 2, 3, 4]);

      order.shuffle(initialIndex: 3);

      expect(order.indices.first, 3);
      expect(order.indices.toSet(), {0, 1, 2, 3, 4});
    });

    test('drops a removed range and closes the gap', () {
      final order = orderOf([2, 0, 3, 1]);

      order.removeRange(1, 2);

      expect(order.indices, [1, 0, 2]);
    });
  });
}
