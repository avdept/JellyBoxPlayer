import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/models/models.dart';

typedef _Template = ({String label, String host, String path, String? icon});

const _templates = <String, _Template>{
  ExternalIdProvider.musicBrainzAlbum: (
    label: 'MusicBrainz release',
    host: 'musicbrainz.org',
    path: 'release',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.musicBrainzReleaseGroup: (
    label: 'MusicBrainz release group',
    host: 'musicbrainz.org',
    path: 'release-group',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.musicBrainzArtist: (
    label: 'MusicBrainz artist',
    host: 'musicbrainz.org',
    path: 'artist',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.musicBrainzAlbumArtist: (
    label: 'MusicBrainz artist',
    host: 'musicbrainz.org',
    path: 'artist',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.musicBrainzTrack: (
    label: 'MusicBrainz track',
    host: 'musicbrainz.org',
    path: 'track',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.musicBrainzRecording: (
    label: 'MusicBrainz recording',
    host: 'musicbrainz.org',
    path: 'recording',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.discogsRelease: (
    label: 'Discogs release',
    host: 'www.discogs.com',
    path: 'release',
    icon: SvgPictures.discogsLogo,
  ),
  ExternalIdProvider.discogsMaster: (
    label: 'Discogs master',
    host: 'www.discogs.com',
    path: 'master',
    icon: SvgPictures.discogsLogo,
  ),
  ExternalIdProvider.discogsArtist: (
    label: 'Discogs artist',
    host: 'www.discogs.com',
    path: 'artist',
    icon: SvgPictures.discogsLogo,
  ),
  ExternalIdProvider.audioDbAlbum: (
    label: 'TheAudioDB album',
    host: 'www.theaudiodb.com',
    path: 'album',
    icon: null,
  ),
  ExternalIdProvider.audioDbArtist: (
    label: 'TheAudioDB artist',
    host: 'www.theaudiodb.com',
    path: 'artist',
    icon: null,
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
          (
            provider: provider,
            label: template.label,
            icon: template.icon,
            uri: uri,
          ),
  ];
}
