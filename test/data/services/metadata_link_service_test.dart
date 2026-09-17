import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/services/metadata_link_service.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  group('metadataLinksFor', () {
    test('- builds one link per known provider in a stable order', () {
      final links = metadataLinksFor({
        ExternalIdProvider.discogsRelease: '123',
        ExternalIdProvider.musicBrainzAlbum: 'rel-1',
        ExternalIdProvider.musicBrainzReleaseGroup: 'grp-1',
        ExternalIdProvider.audioDbAlbum: '456',
      });

      expect(links.map((l) => l.uri.toString()), [
        'https://musicbrainz.org/release/rel-1',
        'https://musicbrainz.org/release-group/grp-1',
        'https://www.discogs.com/release/123',
        'https://www.theaudiodb.com/album/456',
      ]);
      expect(links.first.label, 'MusicBrainz release');
      expect(links.first.provider, ExternalIdProvider.musicBrainzAlbum);
    });

    test('- covers song, artist and recording providers', () {
      final links = metadataLinksFor({
        ExternalIdProvider.musicBrainzTrack: 'trk',
        ExternalIdProvider.musicBrainzRecording: 'rec',
        ExternalIdProvider.musicBrainzArtist: 'art',
        ExternalIdProvider.discogsMaster: '7',
        ExternalIdProvider.discogsArtist: '8',
        ExternalIdProvider.audioDbArtist: '9',
      });

      expect(links.map((l) => l.uri.toString()), [
        'https://musicbrainz.org/artist/art',
        'https://musicbrainz.org/track/trk',
        'https://musicbrainz.org/recording/rec',
        'https://www.discogs.com/master/7',
        'https://www.discogs.com/artist/8',
        'https://www.theaudiodb.com/artist/9',
      ]);
    });

    test('- collapses artist and album artist pointing at the same id', () {
      final links = metadataLinksFor({
        ExternalIdProvider.musicBrainzArtist: 'same',
        ExternalIdProvider.musicBrainzAlbumArtist: 'same',
      });

      expect(links.map((l) => l.uri.toString()), [
        'https://musicbrainz.org/artist/same',
      ]);
    });

    test('- keeps artist and album artist when they differ', () {
      final links = metadataLinksFor({
        ExternalIdProvider.musicBrainzArtist: 'a',
        ExternalIdProvider.musicBrainzAlbumArtist: 'b',
      });

      expect(links.map((l) => l.uri.pathSegments.last), ['a', 'b']);
    });

    test('- ignores unknown providers and blank ids', () {
      expect(
        metadataLinksFor({
          'Imdb': 'tt123',
          ExternalIdProvider.musicBrainzAlbum: '',
        }),
        isEmpty,
      );
    });

    test('- percent-encodes ids that are not URL safe', () {
      final links = metadataLinksFor({
        ExternalIdProvider.discogsRelease: 'a b/c',
      });

      expect(
        links.single.uri.toString(),
        'https://www.discogs.com/release/a%20b%2Fc',
      );
    });
  });
}
