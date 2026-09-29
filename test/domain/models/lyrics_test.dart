import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/mappers/lyrics_dto_mapper.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  final line = LyricsDTO.fromJson({
    'Metadata': <String, dynamic>{},
    'Lyrics': [
      {
        'Text': 'Give me your everything now',
        'Start': 423100000,
        'Cues': [
          {
            'Position': 0,
            'EndPosition': 5,
            'Start': 423100000,
            'End': 424900000,
          },
          {
            'Position': 5,
            'EndPosition': 8,
            'Start': 424900000,
            'End': 426400000,
          },
          {
            'Position': 8,
            'EndPosition': 13,
            'Start': 426400000,
            'End': 429400000,
          },
          {
            'Position': 13,
            'EndPosition': 24,
            'Start': 429400000,
            'End': 438800000,
          },
          {
            'Position': 24,
            'EndPosition': 27,
            'Start': 438800000,
            'End': 449000000,
          },
        ],
      },
    ],
  }).toLyrics().lines.single;

  String word(LyricWordProgress progress) => line.text.substring(
    progress.cue.position,
    progress.cue.endPosition,
  );

  group('LyricLine.wordProgressAt', () {
    test('- is null before the first word starts', () {
      expect(
        line.wordProgressAt(const Duration(seconds: 42, milliseconds: 300)),
        isNull,
      );
    });

    test('- picks the word being sung and how far into it we are', () {
      final progress = line.wordProgressAt(
        const Duration(seconds: 42, milliseconds: 790),
      )!;

      expect(word(progress), 'your ');
      expect(progress.fraction, closeWith(0.5));
    });

    test('- starts the next word exactly at its start time', () {
      final progress = line.wordProgressAt(
        const Duration(seconds: 42, milliseconds: 490),
      )!;

      expect(word(progress), 'me ');
      expect(progress.fraction, 0);
    });

    test('- holds the last word fully sung after the line ends', () {
      final progress = line.wordProgressAt(const Duration(seconds: 50))!;

      expect(word(progress), 'now');
      expect(progress.fraction, 1);
    });

    test('- falls back to the next word start when a cue has no end', () {
      const open = LyricLine(
        text: 'a b',
        cues: [
          LyricCue(start: Duration.zero, endPosition: 2),
          LyricCue(
            start: Duration(seconds: 2),
            position: 2,
            endPosition: 3,
          ),
        ],
      );

      expect(
        open.wordProgressAt(const Duration(seconds: 1))!.fraction,
        closeWith(0.5),
      );
      expect(open.wordProgressAt(const Duration(seconds: 3))!.fraction, 1);
    });
  });
}

Matcher closeWith(double value) => closeTo(value, 1e-9);
