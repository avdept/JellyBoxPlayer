import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/dto/dto.dart';

void main() {
  group('LyricsDTO', () {
    test('- parses a synced payload and converts ticks to durations', () {
      final lyrics = LyricsDTO.fromJson({
        'Metadata': {
          'Artist': 'Portishead',
          'Album': 'Dummy',
          'Title': 'Roads',
          'Length': 3000000000,
          'IsSynced': true,
        },
        'Lyrics': [
          {'Text': 'Oh, can it be', 'Start': 0},
          {'Text': 'The voices calling me', 'Start': 100000000},
          {'Text': 'They get lost', 'Start': 200000000},
        ],
      });

      expect(lyrics.isSynced, isTrue);
      expect(lyrics.metadata.title, 'Roads');
      expect(lyrics.metadata.duration, const Duration(minutes: 5));
      expect(lyrics.lyrics, hasLength(3));
      expect(lyrics.lyrics.first.text, 'Oh, can it be');
      expect(lyrics.lyrics[1].startTime, const Duration(seconds: 10));
      expect(lyrics.lyrics.last.startTime, const Duration(seconds: 20));
    });

    test('- keeps sub-second precision', () {
      final line = LyricLineDTO.fromJson({'Text': 'x', 'Start': 123400000});

      expect(line.startTime, const Duration(milliseconds: 12340));
    });

    test('- reports unsynced lyrics as such and leaves starts null', () {
      final lyrics = LyricsDTO.fromJson({
        'Metadata': {'IsSynced': false},
        'Lyrics': [
          {'Text': 'A plain text line'},
          {'Text': 'Another one'},
        ],
      });

      expect(lyrics.isSynced, isFalse);
      expect(lyrics.lyrics.every((line) => line.startTime == null), isTrue);
    });

    test('- falls back to the lines when IsSynced is missing', () {
      final synced = LyricsDTO.fromJson({
        'Metadata': <String, dynamic>{},
        'Lyrics': [
          {'Text': 'timed', 'Start': 100000000},
        ],
      });
      final unsynced = LyricsDTO.fromJson({
        'Metadata': <String, dynamic>{},
        'Lyrics': [
          {'Text': 'untimed'},
        ],
      });

      expect(synced.isSynced, isTrue);
      expect(unsynced.isSynced, isFalse);
    });

    test('- exposes the LRC offset as a duration', () {
      final withOffset = LyricsDTO.fromJson({
        'Metadata': {'Offset': 5000000},
        'Lyrics': <dynamic>[],
      });
      final withoutOffset = LyricsDTO.fromJson({
        'Metadata': <String, dynamic>{},
        'Lyrics': <dynamic>[],
      });

      expect(withOffset.offset, const Duration(milliseconds: 500));
      expect(withoutOffset.offset, Duration.zero);
    });

    test('- parses ELRC word cues', () {
      final lyrics = LyricsDTO.fromJson({
        'Metadata': {'IsSynced': true},
        'Lyrics': [
          {
            'Text': 'Never gonna',
            'Start': 100000000,
            'Cues': [
              {
                'Position': 0,
                'EndPosition': 5,
                'Start': 100000000,
                'End': 105000000,
              },
              {'Position': 6, 'EndPosition': 11, 'Start': 105000000},
            ],
          },
        ],
      });

      expect(lyrics.hasWordCues, isTrue);
      final cues = lyrics.lyrics.single.cues!;
      expect(cues, hasLength(2));
      expect(cues.first.position, 0);
      expect(cues.first.endPosition, 5);
      expect(cues.first.startTime, const Duration(seconds: 10));
      expect(cues.first.endTime, const Duration(milliseconds: 10500));
      expect(cues.last.endTime, isNull);
    });

    test('- reports no word cues for plain LRC', () {
      final lyrics = LyricsDTO.fromJson({
        'Metadata': {'IsSynced': true},
        'Lyrics': [
          {'Text': 'a line', 'Start': 0},
        ],
      });

      expect(lyrics.hasWordCues, isFalse);
      expect(lyrics.lyrics.single.cues, isNull);
    });

    test('- tolerates an empty response body', () {
      final lyrics = LyricsDTO.fromJson(<String, dynamic>{});

      expect(lyrics.lyrics, isEmpty);
      expect(lyrics.isSynced, isFalse);
      expect(lyrics.offset, Duration.zero);
      expect(lyrics.metadata.title, isNull);
    });
  });

  group('ItemDTO', () {
    test('- picks up HasLyrics', () {
      ItemDTO song(Map<String, dynamic> extra) => ItemDTO.fromJson({
        'Id': 'song-1',
        'Name': 'Roads',
        'Type': 'Audio',
        ...extra,
      });

      expect(song({'HasLyrics': true}).hasLyrics, isTrue);
      expect(song({'HasLyrics': false}).hasLyrics, isFalse);
      expect(song({}).hasLyrics, isFalse);
    });
  });
}
