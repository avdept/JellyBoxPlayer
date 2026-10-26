import 'dart:convert';

import 'package:jplayer/src/domain/models/models.dart';

final _lineTags = RegExp(r'^((?:\[\d{1,3}:\d{1,2}(?:[.:]\d{1,3})?\])+)(.*)$');
final _timeTag = RegExp(r'[\[<](\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?[\]>]');
final _offsetTag = RegExp(
  r'^\[offset:\s*([+-]?\d+)\s*\]$',
  caseSensitive: false,
);
final _wordTag = RegExp(r'<(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?>');

Lyrics? lyricsFromLrc(String source) {
  var offset = Duration.zero;
  final entries = <(Duration, String)>[];
  for (final raw in LineSplitter.split(source)) {
    final line = raw.trim();
    final offsetMatch = _offsetTag.firstMatch(line);
    if (offsetMatch != null) {
      offset = Duration(milliseconds: int.parse(offsetMatch.group(1)!));
      continue;
    }
    final match = _lineTags.firstMatch(line);
    if (match == null) continue;
    final body = match.group(2)!.trim();
    for (final stamp in _timeTag.allMatches(match.group(1)!)) {
      entries.add((_timeOf(stamp), body));
    }
  }
  if (entries.isEmpty) return null;
  entries.sort((a, b) => a.$1.compareTo(b.$1));
  return Lyrics(
    isSynced: true,
    offset: offset,
    lines: [for (final (start, body) in entries) _line(start, body)],
  );
}

LyricLine _line(Duration start, String body) {
  final tags = _wordTag.allMatches(body).toList();
  if (tags.isEmpty) return LyricLine(text: body, start: start);
  final text = StringBuffer(body.substring(0, tags.first.start));
  final cues = <LyricCue>[];
  for (var i = 0; i < tags.length; i++) {
    final tag = tags[i];
    final segment = body.substring(
      tag.end,
      i + 1 < tags.length ? tags[i + 1].start : body.length,
    );
    final time = _timeOf(tag);
    if (segment.trim().isEmpty) {
      if (cues.isNotEmpty && cues.last.end == null) {
        final open = cues.removeLast();
        cues.add(
          LyricCue(
            start: open.start,
            end: time,
            position: open.position,
            endPosition: open.endPosition,
          ),
        );
      }
      text.write(segment);
      continue;
    }
    final position = text.length;
    text.write(segment);
    cues.add(
      LyricCue(
        start: time,
        position: position,
        endPosition: position + segment.trimRight().length,
      ),
    );
  }
  return LyricLine(text: text.toString().trimRight(), start: start, cues: cues);
}

Duration _timeOf(RegExpMatch match) {
  final fraction = match.group(3);
  return Duration(
    minutes: int.parse(match.group(1)!),
    seconds: int.parse(match.group(2)!),
    milliseconds: switch (fraction?.length) {
      1 => int.parse(fraction!) * 100,
      2 => int.parse(fraction!) * 10,
      3 => int.parse(fraction!),
      _ => 0,
    },
  );
}
