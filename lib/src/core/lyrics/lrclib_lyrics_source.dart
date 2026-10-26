import 'dart:convert';

import 'package:jplayer/src/core/lyrics/lrc_parser.dart';
import 'package:jplayer/src/core/lyrics/lrclib_client.dart';
import 'package:jplayer/src/core/lyrics/lyrics_source.dart';
import 'package:jplayer/src/domain/models/models.dart';

class LrclibLyricsSource implements LyricsSource {
  const LrclibLyricsSource(this._client);

  static const _durationTolerance = Duration(seconds: 5);

  final LrclibClient _client;

  @override
  String get id => 'lrclib';

  @override
  Future<Lyrics?> fetch(LyricsRequest request) async {
    if (request.title.isEmpty || request.artist.isEmpty) return null;
    var track = await _exactMatch(request);
    track ??= _bestMatch(
      await _client.search(trackName: request.title, artistName: request.artist),
      request.duration,
    );
    return track == null ? null : _toLyrics(track);
  }

  Future<LrclibTrack?> _exactMatch(LyricsRequest request) async {
    final album = request.album;
    if (album == null || album.isEmpty || request.duration <= Duration.zero) {
      return null;
    }
    final track = await _client.find(
      trackName: request.title,
      artistName: request.artist,
      albumName: album,
      duration: request.duration,
    );
    if (track == null || track.instrumental) return null;
    return track.hasSynced || track.hasPlain ? track : null;
  }

  LrclibTrack? _bestMatch(List<LrclibTrack> candidates, Duration duration) {
    final usable = [
      for (final track in candidates)
        if (!track.instrumental && (track.hasSynced || track.hasPlain))
          if (duration <= Duration.zero ||
              track.duration == null ||
              (track.duration! - duration).abs() <= _durationTolerance)
            track,
    ];
    if (usable.isEmpty) return null;
    return usable.firstWhere((track) => track.hasSynced, orElse: () => usable.first);
  }

  Lyrics? _toLyrics(LrclibTrack track) {
    if (track.hasSynced) {
      final lyrics = lyricsFromLrc(track.syncedLyrics!);
      if (lyrics != null) return lyrics;
    }
    if (!track.hasPlain) return null;
    return Lyrics(
      lines: [
        for (final line in LineSplitter.split(track.plainLyrics!.trim()))
          LyricLine(text: line.trim()),
      ],
    );
  }
}
