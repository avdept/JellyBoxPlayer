import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/jellyfin/mappers/jellyfin_item_mapper.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  group('externalIds', () {
    test('- normalizes Jellyfin provider keys to app provider names', () {
      final album = ItemDTO.fromJson({
        'Id': 'album-1',
        'Name': 'Dummy',
        'Type': 'MusicAlbum',
        'ProviderIds': {
          'MusicBrainzAlbum': 'release-id',
          'MusicBrainzReleaseGroup': 'group-id',
          'MusicBrainzAlbumArtist': 'artist-id',
          'AudioDbAlbum': '12345',
        },
      }).toJellyfinLibraryItem();

      expect(album.externalIds, {
        ExternalIdProvider.musicBrainzAlbum: 'release-id',
        ExternalIdProvider.musicBrainzReleaseGroup: 'group-id',
        ExternalIdProvider.musicBrainzAlbumArtist: 'artist-id',
        ExternalIdProvider.audioDbAlbum: '12345',
      });
    });

    test('- passes unknown provider keys through verbatim', () {
      final song = ItemDTO.fromJson({
        'Id': 'song-1',
        'Name': 'Roads',
        'Type': 'Audio',
        'ProviderIds': {
          'MusicBrainzTrack': 'track-id',
          'MusicBrainzRecording': 'recording-id',
          'Discogs': '98765',
        },
      }).toJellyfinLibraryItem();

      expect(song.externalIds, {
        ExternalIdProvider.musicBrainzTrack: 'track-id',
        ExternalIdProvider.musicBrainzRecording: 'recording-id',
        'Discogs': '98765',
      });
    });

    test('- is empty when the server sends no ProviderIds', () {
      final song = ItemDTO.fromJson({
        'Id': 'song-1',
        'Name': 'Roads',
        'Type': 'Audio',
      }).toJellyfinLibraryItem();

      expect(song.externalIds, isEmpty);
    });

    test('- maps every item of a page', () {
      final page = ItemsWrapper.fromJson({
        'Items': [
          {
            'Id': 'a',
            'Name': 'A',
            'Type': 'MusicAlbum',
            'ProviderIds': {'MusicBrainzAlbum': 'a-release'},
          },
          {'Id': 'b', 'Name': 'B', 'Type': 'MusicAlbum'},
        ],
        'TotalRecordCount': 2,
      }).toJellyfinLibraryPage();

      expect(page.totalRecordCount, 2);
      expect(page.items.first.externalIds, {
        ExternalIdProvider.musicBrainzAlbum: 'a-release',
      });
      expect(page.items.last.externalIds, isEmpty);
    });
  });
}
