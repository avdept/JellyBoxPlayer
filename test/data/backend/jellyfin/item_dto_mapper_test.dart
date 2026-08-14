import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/jellyfin/mappers/item_dto_mapper.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

ItemDTO _song() => ItemDTO.fromJson({
  'Id': 'song-1',
  'Name': 'Roads',
  'Type': 'Audio',
  'IndexNumber': 3,
  'RunTimeTicks': 3000000000,
  'AlbumId': 'album-1',
  'Album': 'Dummy',
  'AlbumArtist': 'Portishead',
  'AlbumArtists': [
    {'Id': 'artist-1', 'Name': 'Portishead'},
  ],
  'AlbumPrimaryImageTag': 'album-tag',
  'BackdropImageTags': ['backdrop-1', 'backdrop-2'],
  'ImageTags': {'Primary': 'song-tag'},
  'HasLyrics': true,
  'UserData': {
    'PlaybackPositionTicks': 12340000,
    'PlayCount': 4,
    'IsFavorite': true,
    'Played': true,
  },
  'MediaSources': [
    {
      'Container': 'flac',
      'MediaStreams': [
        {
          'Type': 'Audio',
          'Codec': 'flac',
          'BitRate': 900000,
          'SampleRate': 44100,
          'BitDepth': 16,
          'Channels': 2,
          'ChannelLayout': 'stereo',
        },
      ],
    },
  ],
});

void main() {
  group('ItemDTOMapping', () {
    test('- maps every field to its LibraryItem equivalent', () {
      final item = _song().toLibraryItem();

      expect(item.id, 'song-1');
      expect(item.name, 'Roads');
      expect(item.kind, ItemKind.song);
      expect(item.indexNumber, 3);
      expect(item.duration, const Duration(minutes: 5));
      expect(item.albumId, 'album-1');
      expect(item.albumName, 'Dummy');
      expect(item.albumArtist, 'Portishead');
      expect(item.albumArtists, [const ArtistRef(id: 'artist-1', name: 'Portishead')]);
      expect(item.images.primary, 'song-tag');
      expect(item.images.albumPrimary, 'album-tag');
      expect(item.images.backdrops, ['backdrop-1', 'backdrop-2']);
      expect(item.hasLyrics, isTrue);
      expect(item.userData.position, const Duration(milliseconds: 1234));
      expect(item.userData.playCount, 4);
      expect(item.userData.isFavorite, isTrue);
      expect(item.userData.played, isTrue);
      expect(item.audioSources, hasLength(1));
      expect(item.audioSources.single.container, 'flac');
      expect(item.audioSources.single.codec, 'flac');
      expect(item.audioSources.single.bitRate, 900000);
      expect(item.audioSources.single.sampleRate, 44100);
      expect(item.audioSources.single.bitDepth, 16);
      expect(item.audioSources.single.channels, 2);
      expect(item.audioSources.single.channelLayout, 'stereo');
    });

    test('- maps each Jellyfin item type to the matching ItemKind', () {
      ItemKind kindOf(String type) =>
          ItemDTO.fromJson({'Id': 'x', 'Name': 'x', 'Type': type})
              .toLibraryItem()
              .kind;

      expect(kindOf('Audio'), ItemKind.song);
      expect(kindOf('MusicAlbum'), ItemKind.album);
      expect(kindOf('Artist'), ItemKind.artist);
      expect(kindOf('Playlist'), ItemKind.playlist);
      expect(kindOf('MusicGenre'), ItemKind.genre);
      expect(kindOf('CollectionFolder'), ItemKind.library);
      expect(kindOf('Library'), ItemKind.library);
      expect(kindOf('SomethingElse'), ItemKind.unknown);
    });
  });

  group('ItemsWrapperMapping', () {
    test('- maps items and preserves totalRecordCount', () {
      final wrapper = ItemsWrapper.fromJson({
        'Items': [
          {'Id': 'a', 'Name': 'Album A', 'Type': 'MusicAlbum'},
          {'Id': 'b', 'Name': 'Album B', 'Type': 'MusicAlbum'},
        ],
        'TotalRecordCount': 42,
      });

      final page = wrapper.toLibraryPage();

      expect(page.totalRecordCount, 42);
      expect(page.items.map((i) => i.id), ['a', 'b']);
      expect(page.items, everyElement(isA<LibraryItem>()));
    });
  });

  group('PlaybackUserData JSON round-trip', () {
    test('- serializes and deserializes through DurationMillisConverter', () {
      const data = PlaybackUserData(
        position: Duration(milliseconds: 1234),
        playCount: 2,
        isFavorite: true,
      );

      final restored = PlaybackUserData.fromJson(data.toJson());

      expect(restored, data);
    });
  });

  group('LibraryItem JSON round-trip', () {
    test('- serializes and deserializes back to an equal value', () {
      final item = _song().toLibraryItem();

      final restored = LibraryItem.fromJson(item.toJson());

      expect(restored, item);
    });
  });
}
