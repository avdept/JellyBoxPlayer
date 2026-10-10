import 'package:flutter/foundation.dart';
import 'package:jplayer/src/data/backend/library_query.dart';

const letterIndexDigits = '#';

const List<String> letterIndexLetters = [
  letterIndexDigits,
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

@immutable
class LetterOffset {
  const LetterOffset(this.index, {this.total});

  final int index;
  final int? total;

  @override
  bool operator ==(Object other) =>
      other is LetterOffset && other.index == index && other.total == total;

  @override
  int get hashCode => Object.hash(index, total);

  @override
  String toString() => 'LetterOffset($index, total: $total)';
}

String? letterLowerBound(String letter) =>
    letter == letterIndexDigits ? null : letter.toLowerCase();

String letterUpperBound(String letter) => letter == letterIndexDigits
    ? 'a'
    : String.fromCharCode(letter.toLowerCase().codeUnitAt(0) + 1);

String letterSortKey(String? name) => (name ?? '').toLowerCase();

Future<LetterOffset> letterOffsetWith({
  required String letter,
  required SortDirection direction,
  required Future<int> Function(String bound) countBefore,
  required Future<int> Function() total,
}) async {
  if (direction == SortDirection.ascending) {
    final lower = letterLowerBound(letter);
    return LetterOffset(lower == null ? 0 : await countBefore(lower));
  }
  final count = await total();
  return LetterOffset(
    count - await countBefore(letterUpperBound(letter)),
    total: count,
  );
}

Future<LetterOffset> letterOffsetInKeys(
  List<String> sortKeys, {
  required String letter,
  required SortDirection direction,
}) =>
    letterOffsetWith(
      letter: letter,
      direction: direction,
      countBefore: (bound) async =>
          sortKeys.where((key) => key.compareTo(bound) < 0).length,
      total: () async => sortKeys.length,
    ).then(
      (offset) => LetterOffset(offset.index, total: sortKeys.length),
    );
