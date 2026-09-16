abstract final class ExternalIdProvider {
  static const musicBrainzAlbum = 'musicbrainz_album';
  static const musicBrainzReleaseGroup = 'musicbrainz_release_group';
  static const musicBrainzArtist = 'musicbrainz_artist';
  static const musicBrainzAlbumArtist = 'musicbrainz_album_artist';
  static const musicBrainzTrack = 'musicbrainz_track';
  static const musicBrainzRecording = 'musicbrainz_recording';
  static const discogsRelease = 'discogs_release';
  static const discogsMaster = 'discogs_master';
  static const discogsArtist = 'discogs_artist';
  static const audioDbAlbum = 'audiodb_album';
  static const audioDbArtist = 'audiodb_artist';
}

Map<String, String> normalizeExternalIds(
  Map<String, String> raw,
  Map<String, String> keyTable,
) => {
  for (final entry in raw.entries)
    if (entry.value.trim().isNotEmpty)
      keyTable[entry.key] ?? entry.key: entry.value.trim(),
};
