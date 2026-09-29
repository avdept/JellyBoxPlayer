class Lyrics {
  const Lyrics({
    this.lines = const [],
    this.isSynced = false,
    this.offset = Duration.zero,
  });

  final List<LyricLine> lines;
  final bool isSynced;
  final Duration offset;

  bool get isEmpty => lines.isEmpty;

  bool get hasWordCues => lines.any((line) => line.cues.isNotEmpty);
}

class LyricLine {
  const LyricLine({this.text = '', this.start, this.cues = const []});

  final String text;
  final Duration? start;
  final List<LyricCue> cues;

  LyricWordProgress? wordProgressAt(Duration position) {
    if (cues.isEmpty || position < cues.first.start) return null;
    var index = 0;
    for (var i = 1; i < cues.length; i++) {
      if (cues[i].start > position) break;
      index = i;
    }
    final cue = cues[index];
    final end =
        cue.end ?? (index + 1 < cues.length ? cues[index + 1].start : null);
    final length = end == null ? Duration.zero : end - cue.start;
    final fraction = length <= Duration.zero
        ? 1.0
        : ((position - cue.start).inMicroseconds / length.inMicroseconds).clamp(
            0.0,
            1.0,
          );
    return LyricWordProgress(cue: cue, fraction: fraction);
  }
}

class LyricWordProgress {
  const LyricWordProgress({required this.cue, required this.fraction});

  final LyricCue cue;
  final double fraction;
}

class LyricCue {
  const LyricCue({
    required this.start,
    this.end,
    this.position = 0,
    this.endPosition = 0,
  });

  final Duration start;
  final Duration? end;
  final int position;
  final int endPosition;
}
