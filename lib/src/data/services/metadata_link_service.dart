import 'package:jplayer/src/domain/models/models.dart';

typedef _Template = ({String label, String host, String path});

const _templates = <String, _Template>{
  ExternalIdProvider.musicBrainzAlbum: (
    label: 'MusicBrainz release',
    host: 'musicbrainz.org',
    path: 'release',
  ),
  ExternalIdProvider.musicBrainzReleaseGroup: (
    label: 'MusicBrainz release group',
    host: 'musicbrainz.org',
    path: 'release-group',
  ),
  ExternalIdProvider.musicBrainzArtist: (
    label: 'MusicBrainz artist',
    host: 'musicbrainz.org',
    path: 'artist',
  ),
  ExternalIdProvider.musicBrainzAlbumArtist: (
    label: 'MusicBrainz artist',
    host: 'musicbrainz.org',
    path: 'artist',
  ),
  ExternalIdProvider.musicBrainzTrack: (
    label: 'MusicBrainz track',
    host: 'musicbrainz.org',
    path: 'track',
  ),
  ExternalIdProvider.musicBrainzRecording: (
    label: 'MusicBrainz recording',
    host: 'musicbrainz.org',
    path: 'recording',
  ),
  ExternalIdProvider.discogsRelease: (
    label: 'Discogs release',
    host: 'www.discogs.com',
    path: 'release',
  ),
  ExternalIdProvider.discogsMaster: (
    label: 'Discogs master',
    host: 'www.discogs.com',
    path: 'master',
  ),
  ExternalIdProvider.discogsArtist: (
    label: 'Discogs artist',
    host: 'www.discogs.com',
    path: 'artist',
  ),
  ExternalIdProvider.audioDbAlbum: (
    label: 'TheAudioDB album',
    host: 'www.theaudiodb.com',
    path: 'album',
  ),
  ExternalIdProvider.audioDbArtist: (
    label: 'TheAudioDB artist',
    host: 'www.theaudiodb.com',
    path: 'artist',
  ),
};

List<MetadataLink> metadataLinksFor(Map<String, String> externalIds) {
  final seen = <Uri>{};
  return [
    for (final MapEntry(key: provider, value: template) in _templates.entries)
      if (externalIds[provider] case final id? when id.isNotEmpty)
        if (Uri(
              scheme: 'https',
              host: template.host,
              pathSegments: [template.path, id],
            )
            case final uri when seen.add(uri))
          (provider: provider, label: template.label, uri: uri),
  ];
}
