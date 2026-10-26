import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/models/models.dart';

typedef _Template = ({String label, String host, String path, String? icon});

Map<String, _Template> get _templates => <String, _Template>{
  ExternalIdProvider.musicBrainzAlbum: (
    label: S.current.musicBrainzRelease,
    host: 'musicbrainz.org',
    path: 'release',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.musicBrainzReleaseGroup: (
    label: S.current.musicBrainzReleaseGroup,
    host: 'musicbrainz.org',
    path: 'release-group',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.musicBrainzArtist: (
    label: S.current.musicBrainzArtist,
    host: 'musicbrainz.org',
    path: 'artist',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.musicBrainzAlbumArtist: (
    label: S.current.musicBrainzArtist,
    host: 'musicbrainz.org',
    path: 'artist',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.musicBrainzTrack: (
    label: S.current.musicBrainzTrack,
    host: 'musicbrainz.org',
    path: 'track',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.musicBrainzRecording: (
    label: S.current.musicBrainzRecording,
    host: 'musicbrainz.org',
    path: 'recording',
    icon: SvgPictures.musicBrainzLogo,
  ),
  ExternalIdProvider.discogsRelease: (
    label: S.current.discogsRelease,
    host: 'www.discogs.com',
    path: 'release',
    icon: SvgPictures.discogsLogo,
  ),
  ExternalIdProvider.discogsMaster: (
    label: S.current.discogsMaster,
    host: 'www.discogs.com',
    path: 'master',
    icon: SvgPictures.discogsLogo,
  ),
  ExternalIdProvider.discogsArtist: (
    label: S.current.discogsArtist,
    host: 'www.discogs.com',
    path: 'artist',
    icon: SvgPictures.discogsLogo,
  ),
  ExternalIdProvider.audioDbAlbum: (
    label: S.current.theAudioDbAlbum,
    host: 'www.theaudiodb.com',
    path: 'album',
    icon: null,
  ),
  ExternalIdProvider.audioDbArtist: (
    label: S.current.theAudioDbArtist,
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
