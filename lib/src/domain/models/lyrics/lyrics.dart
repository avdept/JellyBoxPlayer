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
