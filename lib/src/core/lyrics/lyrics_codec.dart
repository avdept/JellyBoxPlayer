import 'package:jplayer/src/domain/models/models.dart';

Map<String, Object?> lyricsToJson(Lyrics lyrics) => {
  'synced': lyrics.isSynced,
  'offset': lyrics.offset.inMicroseconds,
  'lines': [
    for (final line in lyrics.lines)
      {
        'text': line.text,
        'start': line.start?.inMicroseconds,
        'cues': [
          for (final cue in line.cues)
            {
              'start': cue.start.inMicroseconds,
              'end': cue.end?.inMicroseconds,
              'position': cue.position,
              'endPosition': cue.endPosition,
            },
        ],
      },
  ],
};

Lyrics lyricsFromJson(Map<String, Object?> json) => Lyrics(
  isSynced: json['synced'] == true,
  offset: Duration(microseconds: (json['offset'] as num?)?.toInt() ?? 0),
  lines: [
    for (final line in (json['lines'] as List<Object?>? ?? const []))
      if (line is Map<String, Object?>)
        LyricLine(
          text: line['text'] as String? ?? '',
          start: switch (line['start']) {
            final num start => Duration(microseconds: start.toInt()),
            _ => null,
          },
          cues: [
            for (final cue in (line['cues'] as List<Object?>? ?? const []))
              if (cue is Map<String, Object?>)
                LyricCue(
                  start: Duration(
                    microseconds: (cue['start'] as num?)?.toInt() ?? 0,
                  ),
                  end: switch (cue['end']) {
                    final num end => Duration(microseconds: end.toInt()),
                    _ => null,
                  },
                  position: (cue['position'] as num?)?.toInt() ?? 0,
                  endPosition: (cue['endPosition'] as num?)?.toInt() ?? 0,
                ),
          ],
        ),
  ],
);
