import 'dart:math';

import 'package:just_audio/just_audio.dart';

class QueueShuffleOrder extends ShuffleOrder {
  QueueShuffleOrder({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  final indices = <int>[];

  int? nextInsertPosition;

  int get lastPosition => indices.length;

  int positionAfterIndex(int index) {
    final position = indices.indexOf(index);
    return position < 0 ? indices.length : position + 1;
  }

  @override
  void shuffle({int? initialIndex}) {
    assert(
      initialIndex == null || indices.contains(initialIndex),
      'initialIndex must be part of the shuffle order',
    );
    if (indices.length <= 1) return;
    indices.shuffle(_random);
    if (initialIndex == null) return;

    final swapPosition = indices.indexOf(initialIndex);
    indices[swapPosition] = indices[0];
    indices[0] = initialIndex;
  }

  @override
  void insert(int index, int count) {
    for (var i = 0; i < indices.length; i++) {
      if (indices[i] >= index) indices[i] += count;
    }

    final newIndices = List.generate(count, (i) => index + i);
    final position = nextInsertPosition;
    nextInsertPosition = null;

    if (position != null) {
      indices.insertAll(position.clamp(0, indices.length), newIndices);
      return;
    }

    for (final newIndex in newIndices) {
      indices.insert(_random.nextInt(indices.length + 1), newIndex);
    }
  }

  @override
  void removeRange(int start, int end) {
    final removed = List.generate(end - start, (i) => start + i).toSet();
    indices.removeWhere(removed.contains);
    for (var i = 0; i < indices.length; i++) {
      if (indices[i] >= end) indices[i] -= end - start;
    }
  }

  @override
  void clear() => indices.clear();
}
