import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/subsonic/mappers/subsonic_item_mapper.dart';
import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  final navidromeSong = <String, Object?>{
    'id': '2TO8LEnlJyT57oDGrCERzu',
    'parent': '6Y0ydCZlaByk73N7b6FJH1',
    'isDir': false,
    'title': 'Gonna Stay',
    'album': 'The World of Hypocrisy',
    'artist': 'Kadawatha',
    'track': 4,
    'year': 2014,
    'genre': 'Alternative Rock',
    'coverArt': 'mf-2TO8LEnlJyT57oDGrCERzu',
    'size': 7815422,
    'contentType': 'audio/mpeg',
    'suffix': 'mp3',
    'duration': 191,
    'bitRate': 320,
    'path': 'Kadawatha/The World of Hypocrisy/01-04 - Gonna Stay.mp3',
    'discNumber': 1,
    'created': '2026-09-18T14:49:54.671618003Z',
    'albumId': '6Y0ydCZlaByk73N7b6FJH1',
    'artistId': '5wLuHJSG0FnF1oAeYr9kcx',
    'type': 'music',
    'musicBrainzId': '37ac48b6-dc4d-4b5e-a19b-e43ddda26bf9',
    'genres': [
      {'name': 'Alternative Rock'},
      {'name': 'Rock'},
    ],
    'channelCount': 2,
    'samplingRate': 44100,
    'bitDepth': 0,
    'artists': [
      {'id': '5wLuHJSG0FnF1oAeYr9kcx', 'name': 'Kadawatha'},
    ],
    'displayArtist': 'Kadawatha',
    'albumArtists': [
      {'id': '5wLuHJSG0FnF1oAeYr9kcx', 'name': 'Kadawatha'},
    ],
    'displayAlbumArtist': 'Kadawatha',
    'playCount': 3,
    'played': '2026-09-18T14:53:19Z',
    'starred': '2026-09-18T14:52:59.655054214Z',
  };

  group('SubsonicChildDTO.toLibraryItem', () {
    test('- maps a Navidrome song', () {
      final song = SubsonicChildDTO.fromJson(navidromeSong).toLibraryItem();

      expect(song.kind, ItemKind.song);
      expect(song.id, '2TO8LEnlJyT57oDGrCERzu');
      expect(song.name, 'Gonna Stay');
      expect(song.indexNumber, 4);
      expect(song.discNumber, 1);
      expect(song.duration, const Duration(seconds: 191));
      expect(song.productionYear, 2014);
      expect(song.albumId, '6Y0ydCZlaByk73N7b6FJH1');
      expect(song.albumName, 'The World of Hypocrisy');
      expect(song.albumArtist, 'Kadawatha');
      expect(song.artists.single.id, '5wLuHJSG0FnF1oAeYr9kcx');
      expect(song.genres, ['Alternative Rock', 'Rock']);
      expect(song.images.primary, 'mf-2TO8LEnlJyT57oDGrCERzu');
      expect(song.images.albumPrimary, 'al-6Y0ydCZlaByk73N7b6FJH1');
      expect(song.images.hasCover, isTrue);
      expect(song.hasLyrics, isTrue);
      expect(song.userData.playCount, 3);
      expect(song.userData.played, isTrue);
      expect(song.userData.isFavorite, isTrue);
      expect(song.externalIds, {
        ExternalIdProvider.musicBrainzRecording:
            '37ac48b6-dc4d-4b5e-a19b-e43ddda26bf9',
      });

      final source = song.audioSources.single;
      expect(source.container, 'mp3');
      expect(source.codec, 'mp3');
      expect(source.bitRate, 320000);
      expect(source.sampleRate, 44100);
      expect(source.channels, 2);
      expect(source.bitDepth, isNull);
    });

    test('- falls back to legacy single-valued fields', () {
      final song = SubsonicChildDTO.fromJson({
        'id': 's1',
        'title': 'Old Client Song',
        'artist': 'Solo',
        'artistId': 'ar-solo',
        'genre': 'Jazz',
        'musicBrainzId': '',
      }).toLibraryItem();

      expect(song.artists, [const ArtistRef(id: 'ar-solo', name: 'Solo')]);
      expect(song.albumArtists, [const ArtistRef(id: 'ar-solo', name: 'Solo')]);
      expect(song.genres, ['Jazz']);
      expect(song.externalIds, isEmpty);
      expect(song.images.hasCover, isFalse);
      expect(song.userData.isFavorite, isFalse);
      expect(song.audioSources.single.codec, isNull);
    });

    test('- derives the codec from the suffix and bit depth', () {
      expect(subsonicCodecForSuffix('m4a', bitDepth: 16), 'alac');
      expect(subsonicCodecForSuffix('m4a', bitDepth: 0), 'aac');
      expect(subsonicCodecForSuffix('M4A'), 'aac');
      expect(subsonicCodecForSuffix('flac', bitDepth: 24), 'flac');
      expect(subsonicCodecForSuffix('ogg'), 'vorbis');
      expect(subsonicCodecForSuffix('wav'), 'pcm');
      expect(subsonicCodecForSuffix('opus'), 'opus');
      expect(subsonicCodecForSuffix(''), isNull);
      expect(subsonicCodecForSuffix(null), isNull);
    });

    test(
      '- reasons about the transcoded container when the server has one',
      () {
        final song = SubsonicChildDTO.fromJson({
          'id': 's1',
          'title': 'Profiled',
          'suffix': 'flac',
          'bitDepth': 24,
          'transcodedSuffix': 'mp3',
          'transcodedContentType': 'audio/mpeg',
        }).toLibraryItem();

        expect(song.audioSources.single.container, 'mp3');
        expect(song.audioSources.single.codec, 'mp3');
      },
    );

    test('- can be told lyrics are unavailable', () {
      final song = SubsonicChildDTO.fromJson({
        'id': 's1',
        'title': 'x',
      }).toLibraryItem(lyricsAvailable: false);

      expect(song.hasLyrics, isFalse);
    });
  });

  group('playlist entry ids', () {
    test('- encode the index and song id and decode them back', () {
      final id = subsonicPlaylistEntryId(7, 'abc:def');
      expect(id, '7:abc:def');
      expect(subsonicPlaylistEntryOf(id), (index: 7, songId: 'abc:def'));
    });

    test('- reject foreign entry ids', () {
      expect(subsonicPlaylistEntryOf('no-colon'), isNull);
      expect(subsonicPlaylistEntryOf('x:song'), isNull);
      expect(subsonicPlaylistEntryOf('-1:song'), isNull);
    });
  });

  test('SubsonicAlbumDTO.toLibraryItem maps album fields', () {
    final album = SubsonicAlbumDTO.fromJson({
      'id': '7v5oTkdcIEWmzlnS3TnrmZ',
      'name': 'Netherworlds',
      'artist': 'Insomnium',
      'artistId': '4klmAi1GYLIVuzBiUxu6re',
      'songCount': 1,
      'duration': 375,
      'created': '2026-09-11T07:56:12.268534116Z',
      'genre': 'Metal',
      'genres': [
        {'name': 'Metal'},
      ],
      'musicBrainzId': '',
      'artists': [
        {'id': '4klmAi1GYLIVuzBiUxu6re', 'name': 'Insomnium'},
      ],
      'displayArtist': 'Insomnium',
      'starred': '2026-09-18T14:52:59Z',
      'playCount': 2,
    }).toLibraryItem();

    expect(album.kind, ItemKind.album);
    expect(album.albumId, album.id);
    expect(album.albumArtist, 'Insomnium');
    expect(album.albumArtists.single.id, '4klmAi1GYLIVuzBiUxu6re');
    expect(album.artistLabel, 'Insomnium');
    expect(album.genres, ['Metal']);
    expect(album.duration, const Duration(seconds: 375));
    expect(album.images.primary, 'al-7v5oTkdcIEWmzlnS3TnrmZ');
    expect(album.userData.isFavorite, isTrue);
    expect(album.userData.playCount, 2);
    expect(album.externalIds, isEmpty);
  });

  test('SubsonicArtistDTO.toLibraryItem maps artist fields', () {
    final artist = SubsonicArtistDTO.fromJson({
      'id': 'ar1',
      'name': 'Insomnium',
      'coverArt': 'ar-ar1_9b51ff9d4a89241c',
      'albumCount': 1,
      'musicBrainzId': 'mbid-1',
    }).toLibraryItem();

    expect(artist.kind, ItemKind.artist);
    expect(artist.images.primary, 'ar-ar1_9b51ff9d4a89241c');
    expect(artist.externalIds, {
      ExternalIdProvider.musicBrainzArtist: 'mbid-1',
    });

    final bare = SubsonicArtistDTO.fromJson({
      'id': 'ar2',
      'name': 'No Art',
    }).toLibraryItem();
    expect(bare.images.primary, 'ar-ar2');
  });

  test('SubsonicPlaylistDTO.toLibraryItem maps playlist fields', () {
    final playlist = SubsonicPlaylistDTO.fromJson({
      'id': 'pl1',
      'name': 'Road trip',
      'comment': 'windows down',
      'public': true,
      'songCount': 12,
      'duration': 3000,
      'coverArt': 'pl-pl1',
    }).toLibraryItem();

    expect(playlist.kind, ItemKind.playlist);
    expect(playlist.overview, 'windows down');
    expect(playlist.duration, const Duration(seconds: 3000));
    expect(playlist.images.primary, 'pl-pl1');
  });

  test('genres and music folders become browsable items', () {
    final genre = const SubsonicGenreDTO(
      value: 'Heavy Metal',
      songCount: 96,
      albumCount: 9,
    ).toLibraryItem();
    expect(genre.kind, ItemKind.genre);
    expect(genre.id, 'Heavy Metal');
    expect(genre.name, 'Heavy Metal');

    final library = SubsonicMusicFolderDTO.fromJson({
      'id': 1,
      'name': 'Music Library',
    }).toLibraryItem();
    expect(library.kind, ItemKind.library);
    expect(library.id, '1');
    expect(library.collectionType, 'music');
  });
}
