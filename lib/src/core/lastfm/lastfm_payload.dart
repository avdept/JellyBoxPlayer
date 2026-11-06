import 'package:jplayer/src/core/listenbrainz/listenbrainz_payload.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/domain/models/models.dart';

Map<String, String> lastFmTrackParams(
  Listen listen, {
  int? index,
  bool withTimestamp = true,
}) {
  final song = listen.song;
  final album = listen.album;
  final artist = _artistName(song, album);
  final albumArtist =
      _presence(album?.albumArtist) ?? _presence(song.albumArtist);
  final albumName = _presence(song.albumName) ?? _presence(album?.name);
  final recordingId = musicBrainzIds(
    song.externalIds[ExternalIdProvider.musicBrainzRecording],
  ).firstOrNull;
  final seconds = song.duration.inSeconds;
  final suffix = index == null ? '' : '[$index]';

  return {
    'artist$suffix': artist,
    'track$suffix': _presence(song.name) ?? 'Unknown track',
    'album$suffix': ?albumName,
    if (albumArtist != null && albumArtist != artist)
      'albumArtist$suffix': albumArtist,
    if (song.indexNumber > 0) 'trackNumber$suffix': '${song.indexNumber}',
    if (seconds > 0) 'duration$suffix': '$seconds',
    'mbid$suffix': ?recordingId,
    if (withTimestamp)
      'timestamp$suffix':
          '${listen.listenedAt.toUtc().millisecondsSinceEpoch ~/ 1000}',
  };
}

Map<String, String> lastFmScrobbleParams(List<Listen> listens) => {
  for (final (index, listen) in listens.indexed)
    ...lastFmTrackParams(listen, index: index),
};

String _artistName(LibraryItem song, LibraryItem? album) =>
    _presence(song.effectiveArtists.firstOrNull?.name) ??
    _presence(song.albumArtist) ??
    _presence(album?.albumArtist) ??
    _presence(album?.artistLabel) ??
    'Unknown artist';

String? _presence(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
