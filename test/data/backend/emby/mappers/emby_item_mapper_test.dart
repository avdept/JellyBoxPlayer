import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/emby/mappers/emby_item_mapper.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  group('hasLyrics', () {
    test('- is derived from an lrc subtitle stream, which Emby uses '
        'instead of HasLyrics', () {
      final song = ItemDTO.fromJson({
        'Id': '57',
        'Name': 'Scavenger',
        'Type': 'Audio',
        'MediaSources': [
          {
            'Id': 'mediasource_57',
            'Container': 'flac',
            'MediaStreams': [
              {'Index': 0, 'Type': 'Audio', 'Codec': 'flac'},
              {'Index': 1, 'Type': 'EmbeddedImage', 'Codec': 'mjpeg'},
              {'Index': 2, 'Type': 'Subtitle', 'Codec': 'lrc'},
            ],
          },
        ],
      }).toEmbyLibraryItem();

      expect(song.hasLyrics, isTrue);
    });

    test('- stays false for a song with no lyric stream', () {
      final song = ItemDTO.fromJson({
        'Id': '11',
        'Name': 'Android of the Sandstorm',
        'Type': 'Audio',
        'MediaSources': [
          {
            'Id': 'mediasource_11',
            'Container': 'mp3',
            'MediaStreams': [
              {'Index': 0, 'Type': 'Audio', 'Codec': 'mp3'},
            ],
          },
        ],
      }).toEmbyLibraryItem();

      expect(song.hasLyrics, isFalse);
    });

    test('- ignores a real subtitle stream that is not lyrics', () {
      final song = ItemDTO.fromJson({
        'Id': '12',
        'Name': 'With subs',
        'Type': 'Audio',
        'MediaSources': [
          {
            'Id': 'mediasource_12',
            'MediaStreams': [
              {'Index': 1, 'Type': 'Subtitle', 'Codec': 'srt'},
            ],
          },
        ],
      }).toEmbyLibraryItem();

      expect(song.hasLyrics, isFalse);
    });
  });

  group('primary image', () {
    LibraryItem albumWith(Map<String, Object?> extra) => ItemDTO.fromJson({
      'Id': '73',
      'Name': 'Raised on Whipped Cream',
      'Type': 'MusicAlbum',
      ...extra,
    }).toEmbyLibraryItem();

    test('- borrows the cover of the track that owns it', () {
      final album = albumWith({
        'ImageTags': <String, String>{},
        'PrimaryImageTag': 'fd3310e09ee86e624013d6c57558842f',
        'PrimaryImageItemId': '52',
      });

      expect(album.images.primary, 'fd3310e09ee86e624013d6c57558842f');
      expect(album.images.primaryItemId, '52');
      expect(album.primaryImageId, '52');
    });

    test('- prefers the album own cover when it has one', () {
      final album = albumWith({
        'ImageTags': {'Primary': '2b44233a0b249dd404412a22d5dd8d7c'},
        'PrimaryImageTag': 'should-be-ignored',
        'PrimaryImageItemId': '99',
      });

      expect(album.images.primary, '2b44233a0b249dd404412a22d5dd8d7c');
      expect(album.images.primaryItemId, isNull);
      expect(album.primaryImageId, '73');
    });

    test('- stays imageless when Emby reports no cover at all', () {
      final album = albumWith({'ImageTags': <String, String>{}});

      expect(album.images.primary, isNull);
      expect(album.primaryImageId, '73');
    });
  });

  group('play count', () {
    LibraryItem songWith(Map<String, Object?> userData) => ItemDTO.fromJson({
      'Id': '11',
      'Name': 'Android of the Sandstorm',
      'Type': 'Audio',
      'UserData': userData,
    }).toEmbyLibraryItem();

    test('- counts a played song as one play, since Emby list responses '
        'always report PlayCount 0', () {
      final song = songWith({'Played': true, 'PlayCount': 0});

      expect(song.userData.played, isTrue);
      expect(song.userData.playCount, 1);
    });

    test('- keeps a real count when Emby does report one', () {
      final song = songWith({'Played': true, 'PlayCount': 3});

      expect(song.userData.playCount, 3);
    });

    test('- leaves an unplayed song at zero', () {
      final song = songWith({'Played': false, 'PlayCount': 0});

      expect(song.userData.playCount, 0);
    });
  });
}
