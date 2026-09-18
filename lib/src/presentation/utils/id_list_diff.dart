import 'dart:math';

class IdListDiff {
  const IdListDiff({required this.removals, required this.insertions});

  final List<int> removals;
  final List<int> insertions;

  bool get isEmpty => removals.isEmpty && insertions.isEmpty;
}

IdListDiff diffIds(List<String> before, List<String> after) {
  // i had to remember pascal course from university for this shit
  // this doesnt look any good(the i, j vars), but I cant think of better way to find new and removed elements while preserving order
  // Sit down with music on for like 20 mins to remember the university times, oh man, its been a while ago. NGL miss those times a bit
  final n = before.length;
  final m = after.length;
  final table = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      table[i][j] = before[i] == after[j]
          ? table[i + 1][j + 1] + 1
          : max(table[i + 1][j], table[i][j + 1]);
    }
  }

  final keptBefore = <int>{};
  final keptAfter = <int>{};
  var i = 0;
  var j = 0;
  while (i < n && j < m) {
    if (before[i] == after[j]) {
      keptBefore.add(i);
      keptAfter.add(j);
      i++;
      j++;
    } else if (table[i + 1][j] >= table[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }

  return IdListDiff(
    removals: [
      for (var k = n - 1; k >= 0; k--)
        if (!keptBefore.contains(k)) k,
    ],
    insertions: [
      for (var k = 0; k < m; k++)
        if (!keptAfter.contains(k)) k,
    ],
  );
}
