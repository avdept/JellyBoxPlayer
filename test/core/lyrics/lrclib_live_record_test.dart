import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/lyrics/lrc_parser.dart';
import 'package:jplayer/src/core/lyrics/lrclib_client.dart';

void main() {
  test('parses a real LRCLIB record (Insomnium - The Banished)', () {
    final json =
        jsonDecode(
              File(
                'test/fixtures/lrclib/the_banished.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final track = LrclibTrack.fromJson(json);

    expect(track.id, 39343703);
    expect(track.trackName, 'The Banished');
    expect(track.artistName, 'Insomnium');
    expect(track.duration, const Duration(seconds: 326));
    expect(track.instrumental, isFalse);
    expect(track.hasSynced, isTrue);

    final lyrics = lyricsFromLrc(track.syncedLyrics!)!;

    expect(lyrics.isSynced, isTrue);
    expect(lyrics.lines, hasLength(42));
    expect(lyrics.lines.first.text, 'Narrow is the path in the night');
    expect(
      lyrics.lines.first.start,
      const Duration(seconds: 38, milliseconds: 600),
    );
    expect(lyrics.lines.last.text, isEmpty);
    expect(
      lyrics.lines.last.start,
      const Duration(minutes: 5, seconds: 16, milliseconds: 740),
    );
    for (var i = 1; i < lyrics.lines.length; i++) {
      expect(
        lyrics.lines[i].start! >= lyrics.lines[i - 1].start!,
        isTrue,
      );
    }
    expect(lyrics.lines.every((line) => line.cues.isEmpty), isTrue);
  });
}
