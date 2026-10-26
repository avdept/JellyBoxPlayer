import 'package:jplayer/src/domain/models/models.dart';

class LyricsRequest {
  const LyricsRequest({
    required this.itemId,
    this.title = '',
    this.artist = '',
    this.album,
    this.duration = Duration.zero,
  });

  factory LyricsRequest.forSong(LibraryItem song) => LyricsRequest(
    itemId: song.id,
    title: song.name,
    artist: song.effectiveArtists.isNotEmpty
        ? song.effectiveArtists.first.name
        : (song.albumArtist ?? ''),
    album: song.albumName,
    duration: song.duration,
  );

  final String itemId;
  final String title;
  final String artist;
  final String? album;
  final Duration duration;
}

abstract class LyricsSource {
  String get id;

  Future<Lyrics?> fetch(LyricsRequest request);
}

Future<Lyrics?> resolveLyrics(
  List<LyricsSource> sources,
  LyricsRequest request,
) async {
  Object? error;
  StackTrace? stackTrace;
  var resolved = false;
  for (final source in sources) {
    try {
      final lyrics = await source.fetch(request);
      resolved = true;
      if (lyrics != null && lyrics.lines.isNotEmpty) return lyrics;
    } catch (e, s) {
      error ??= e;
      stackTrace ??= s;
    }
  }
  if (!resolved && error != null) {
    Error.throwWithStackTrace(error, stackTrace!);
  }
  return null;
}
