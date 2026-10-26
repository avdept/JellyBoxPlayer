import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/lyrics/lrc_parser.dart';

void main() {
  test('parses line-synced LRC and skips metadata tags', () {
    final lyrics = lyricsFromLrc('''
[ar:Some Artist]
[ti:Some Title]
[00:17.12] I feel your breath upon my neck
[00:12.00] Earlier line
[01:20.853] Millisecond line
''');

    expect(lyrics, isNotNull);
    expect(lyrics!.isSynced, isTrue);
    expect(lyrics.offset, Duration.zero);
    expect(lyrics.lines, hasLength(3));
    expect(lyrics.lines[0].text, 'Earlier line');
    expect(lyrics.lines[0].start, const Duration(seconds: 12));
    expect(lyrics.lines[1].text, 'I feel your breath upon my neck');
    expect(
      lyrics.lines[1].start,
      const Duration(seconds: 17, milliseconds: 120),
    );
    expect(
      lyrics.lines[2].start,
      const Duration(minutes: 1, seconds: 20, milliseconds: 853),
    );
  });

  test('expands repeated timestamps on one line', () {
    final lyrics = lyricsFromLrc('[00:05.00][00:25.00] Chorus line');

    expect(lyrics!.lines, hasLength(2));
    expect(lyrics.lines[0].start, const Duration(seconds: 5));
    expect(lyrics.lines[1].start, const Duration(seconds: 25));
    expect(lyrics.lines[1].text, 'Chorus line');
  });

  test('keeps empty timestamped lines as gaps', () {
    final lyrics = lyricsFromLrc('[00:01.00] First\n[00:09.00]\n[00:12.00] Next');

    expect(lyrics!.lines, hasLength(3));
    expect(lyrics.lines[1].text, isEmpty);
    expect(lyrics.lines[1].start, const Duration(seconds: 9));
  });

  test('reads the offset tag', () {
    final lyrics = lyricsFromLrc('[offset:+500]\n[00:10.00] Line');

    expect(lyrics!.offset, const Duration(milliseconds: 500));
  });

  test('parses enhanced word cues with character positions', () {
    final lyrics = lyricsFromLrc(
      '[00:10.00] <00:10.00>Never <00:10.50>gonna <00:11.00>give <00:11.80>',
    );

    final line = lyrics!.lines.single;
    expect(line.text, 'Never gonna give');
    expect(line.cues, hasLength(3));
    expect(line.cues[0].start, const Duration(seconds: 10));
    expect(line.cues[0].position, 0);
    expect(line.cues[0].endPosition, 5);
    expect(line.cues[1].position, 6);
    expect(line.cues[1].endPosition, 11);
    expect(line.cues[2].position, 12);
    expect(line.cues[2].endPosition, 16);
    expect(
      line.cues[2].end,
      const Duration(seconds: 11, milliseconds: 800),
    );
  });

  test('returns null for text without timestamps', () {
    expect(lyricsFromLrc('Just some plain text\nAnother line'), isNull);
    expect(lyricsFromLrc(''), isNull);
  });
}
