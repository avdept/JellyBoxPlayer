import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/domain/models/models.dart';

const listenBrainzClientName = 'JellyBox Player';

final _mbidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

final _mbidSeparators = RegExp(r'[;,/\s]+');

List<String> musicBrainzIds(String? raw) {
  if (raw == null) return const [];
  return [
    for (final part in raw.split(_mbidSeparators))
      if (part.trim().toLowerCase() case final id
          when _mbidPattern.hasMatch(id))
        id,
  ];
}

Map<String, Object?> listenBrainzPayload(
  Listen listen, {
  required String clientVersion,
  bool withTimestamp = true,
}) {
  final song = listen.song;
  final album = listen.album;
  String? idFor(String key) => song.externalIds[key] ?? album?.externalIds[key];

  final artistIds =
      [
            song.externalIds[ExternalIdProvider.musicBrainzArtist],
            idFor(ExternalIdProvider.musicBrainzAlbumArtist),
            album?.externalIds[ExternalIdProvider.musicBrainzArtist],
          ]
          .map(musicBrainzIds)
          .firstWhere(
            (ids) => ids.isNotEmpty,
            orElse: () => const [],
          );

  final recordingId = musicBrainzIds(
    song.externalIds[ExternalIdProvider.musicBrainzRecording],
  ).firstOrNull;
  final trackId = musicBrainzIds(
    song.externalIds[ExternalIdProvider.musicBrainzTrack],
  ).firstOrNull;
  final releaseId = musicBrainzIds(
    idFor(ExternalIdProvider.musicBrainzAlbum),
  ).firstOrNull;
  final releaseGroupId = musicBrainzIds(
    idFor(ExternalIdProvider.musicBrainzReleaseGroup),
  ).firstOrNull;

  final releaseName = _presence(song.albumName) ?? _presence(album?.name);
  final artistMbids = artistIds.isEmpty ? null : artistIds;
  final disc = (song.discNumber ?? 0) > 0 ? song.discNumber : null;
  final durationMs = song.duration.inMilliseconds;

  return {
    if (withTimestamp)
      'listened_at': listen.listenedAt.toUtc().millisecondsSinceEpoch ~/ 1000,
    'track_metadata': {
      'artist_name': _artistName(song, album),
      'track_name': _presence(song.name) ?? 'Unknown track',
      'release_name': ?releaseName,
      'additional_info': {
        'media_player': listenBrainzClientName,
        'media_player_version': clientVersion,
        'submission_client': listenBrainzClientName,
        'submission_client_version': clientVersion,
        if (durationMs > 0) 'duration_ms': durationMs,
        if (song.indexNumber > 0) 'tracknumber': song.indexNumber,
        'discnumber': ?disc,
        'artist_mbids': ?artistMbids,
        'recording_mbid': ?recordingId,
        'track_mbid': ?trackId,
        'release_mbid': ?releaseId,
        'release_group_mbid': ?releaseGroupId,
      },
    },
  };
}

String _artistName(LibraryItem song, LibraryItem? album) =>
    _presence(song.artistLabel) ??
    _presence(album?.albumArtist) ??
    _presence(album?.artistLabel) ??
    'Unknown artist';

String? _presence(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
