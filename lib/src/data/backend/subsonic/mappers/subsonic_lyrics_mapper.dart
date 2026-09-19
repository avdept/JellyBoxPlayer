import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

extension SubsonicLyricsMapping on SubsonicLyricsListDTO {
  Lyrics? toLyrics() {
    if (structuredLyrics.isEmpty) return null;
    final chosen = structuredLyrics.firstWhere(
      (lyrics) => lyrics.synced && lyrics.line.isNotEmpty,
      orElse: () => structuredLyrics.firstWhere(
        (lyrics) => lyrics.line.isNotEmpty,
        orElse: () => structuredLyrics.first,
      ),
    );
    if (chosen.line.isEmpty) return null;
    return Lyrics(
      isSynced: chosen.synced,
      offset: Duration(milliseconds: chosen.offset ?? 0),
      lines: [
        for (final line in chosen.line)
          LyricLine(
            text: line.value,
            start: chosen.synced && line.start != null
                ? Duration(milliseconds: line.start!)
                : null,
          ),
      ],
    );
  }
}
