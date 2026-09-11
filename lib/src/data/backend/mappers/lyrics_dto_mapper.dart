import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

extension LyricsDTOMapping on LyricsDTO {
  Lyrics toLyrics() => Lyrics(
    lines: [
      for (final line in lyrics)
        LyricLine(
          text: line.text,
          start: line.startTime,
          cues: [
            for (final cue in line.cues ?? const <LyricLineCueDTO>[])
              LyricCue(
                start: cue.startTime,
                end: cue.endTime,
                position: cue.position,
                endPosition: cue.endPosition,
              ),
          ],
        ),
    ],
    isSynced: isSynced,
    offset: offset,
  );
}
