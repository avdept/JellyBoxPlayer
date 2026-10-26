import 'package:jplayer/src/core/lyrics/lyrics_source.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/domain/models/models.dart';

class ServerLyricsSource implements LyricsSource {
  const ServerLyricsSource(this._client);

  final MediaServerClient _client;

  @override
  String get id => 'server';

  @override
  Future<Lyrics?> fetch(LyricsRequest request) => _client.getLyrics(request.itemId);
}
