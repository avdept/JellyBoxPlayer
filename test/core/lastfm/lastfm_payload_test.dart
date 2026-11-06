import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/lastfm/lastfm_payload.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  const recording = '2b8e4b2c-1d3a-4f6e-9c1b-0a2b3c4d5e6f';

  const album = LibraryItem(
    id: 'album',
    name: 'Dummy',
    kind: ItemKind.album,
    albumArtist: 'Portishead',
  );

  const song = LibraryItem(
    id: 'song',
    name: 'Sour Times',
    kind: ItemKind.song,
    indexNumber: 2,
    duration: Duration(minutes: 4, seconds: 13),
    albumName: 'Dummy',
    albumArtist: 'Portishead',
    artists: [
      ArtistRef(id: 'a', name: 'Portishead'),
      ArtistRef(id: 'b', name: 'Beth Gibbons'),
    ],
    externalIds: {
      ExternalIdProvider.musicBrainzRecording: recording,
      ExternalIdProvider.musicBrainzTrack:
          '3c9f5c3d-2e4b-4a7f-8d2c-1b3c4d5e6f70',
    },
  );

  final listen = Listen(
    song: song,
    album: album,
    listenedAt: DateTime.utc(2026, 9, 20, 12),
  );

  test('maps a listen onto Last.fm track parameters', () {
    expect(lastFmTrackParams(listen), {
      'artist': 'Portishead',
      'track': 'Sour Times',
      'album': 'Dummy',
      'trackNumber': '2',
      'duration': '253',
      'mbid': recording,
      'timestamp': '1789905600',
    });
  });

  test('sends only the first artist and the album artist when it differs', () {
    final params = lastFmTrackParams(
      Listen(
        song: song.copyWith(
          artists: const [ArtistRef(id: 'x', name: 'Beth Gibbons')],
        ),
        album: album,
        listenedAt: listen.listenedAt,
      ),
    );

    expect(params['artist'], 'Beth Gibbons');
    expect(params['albumArtist'], 'Portishead');
  });

  test('falls back to the album artist and omits empty fields', () {
    final params = lastFmTrackParams(
      Listen(
        song: const LibraryItem(id: 's', name: ' ', kind: ItemKind.song),
        album: album,
        listenedAt: listen.listenedAt,
      ),
      withTimestamp: false,
    );

    expect(params, {
      'artist': 'Portishead',
      'track': 'Unknown track',
      'album': 'Dummy',
    });
  });

  test('indexes a batch of listens', () {
    final params = lastFmScrobbleParams([listen, listen]);

    expect(params['artist[0]'], 'Portishead');
    expect(params['track[1]'], 'Sour Times');
    expect(params['timestamp[1]'], '1789905600');
    expect(params.containsKey('artist'), isFalse);
  });
}
