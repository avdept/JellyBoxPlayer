import 'dart:convert';

import 'package:jplayer/src/data/dto/dto.dart';

const _byteOrderMark = '﻿';

extension SubtitleTrackMapping on SubtitleTrackDTO {
  LyricsDTO toLyricsDTO() => LyricsDTO(
    lyrics: [
      for (final event in trackEvents)
        LyricLineDTO(text: event.text, start: event.startPositionTicks),
    ],
  );
}

SubtitleTrackDTO parseSubtitleTrack(String body) {
  final trimmed = body.startsWith(_byteOrderMark) ? body.substring(1) : body;
  return SubtitleTrackDTO.fromJson(
    jsonDecode(trimmed) as Map<String, dynamic>,
  );
}
