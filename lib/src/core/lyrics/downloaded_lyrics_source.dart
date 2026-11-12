import 'package:jplayer/src/core/lyrics/lyrics_source.dart';
import 'package:jplayer/src/domain/models/models.dart';

class DownloadedLyricsSource implements LyricsSource {
  const DownloadedLyricsSource(this._lyricsOf);

  final Future<Lyrics?> Function(String songId) _lyricsOf;

  @override
  String get id => 'downloaded';

  @override
  Future<Lyrics?> fetch(LyricsRequest request) => _lyricsOf(request.itemId);
}
