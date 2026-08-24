import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/mappers/subtitle_track_mapper.dart';

void main() {
  group('parseSubtitleTrack', () {
    const body =
        '{"TrackEvents":['
        '{"Text":"Yeah!","StartPositionTicks":24000000,'
        '"EndPositionTicks":167600000},'
        '{"Text":"Know you by waste and not by your face",'
        '"StartPositionTicks":167600000,"EndPositionTicks":217800000}]}';

    test('- reads the track events Emby returns', () {
      final track = parseSubtitleTrack(body);

      expect(track.trackEvents, hasLength(2));
      expect(track.trackEvents.first.text, 'Yeah!');
      expect(track.trackEvents.first.startPositionTicks, 24000000);
      expect(track.trackEvents.first.endPositionTicks, 167600000);
    });

    test('- tolerates the UTF-8 byte order mark Emby prefixes', () {
      final track = parseSubtitleTrack('﻿$body');

      expect(track.trackEvents, hasLength(2));
    });

    test('- fails loudly on a body that is not a track', () {
      expect(() => parseSubtitleTrack('not json'), throwsFormatException);
    });
  });

  group('toLyricsDTO', () {
    test('- maps track events onto synced lyric lines', () {
      final lyrics = parseSubtitleTrack(
        '{"TrackEvents":['
        '{"Text":"Yeah!","StartPositionTicks":24000000},'
        '{"Text":"second line","StartPositionTicks":167600000}]}',
      ).toLyricsDTO();

      expect(lyrics.isSynced, isTrue);
      expect(lyrics.lyrics.map((line) => line.text), [
        'Yeah!',
        'second line',
      ]);
      expect(lyrics.lyrics.first.startTime, const Duration(milliseconds: 2400));
      expect(
        lyrics.lyrics.last.startTime,
        const Duration(milliseconds: 16760),
      );
    });

    test('- yields empty unsynced lyrics for an empty track', () {
      final lyrics = parseSubtitleTrack('{"TrackEvents":[]}').toLyricsDTO();

      expect(lyrics.lyrics, isEmpty);
      expect(lyrics.isSynced, isFalse);
    });
  });
}
