import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_payload.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  const recording = '2b8e4b2c-1d3a-4f6e-9c1b-0a2b3c4d5e6f';
  const track = '3c9f5c3d-2e4b-4a7f-8d2c-1b3c4d5e6f70';
  const release = '4d0a6d4e-3f5c-4b80-9e3d-2c4d5e6f7081';
  const group = '5e1b7e5f-4a6d-4c91-8f4e-3d5e6f708192';
  const artistA = '6f2c8f60-5b7e-4da2-9a5f-4e6f708192a3';
  const artistB = '7a3d9a71-6c8f-4eb3-8b60-5f708192a3b4';

  const album = LibraryItem(
    id: 'album',
    name: 'Dummy',
    kind: ItemKind.album,
    albumArtist: 'Portishead',
    externalIds: {
      ExternalIdProvider.musicBrainzAlbum: release,
      ExternalIdProvider.musicBrainzReleaseGroup: group,
      ExternalIdProvider.musicBrainzAlbumArtist: artistA,
    },
  );

  const song = LibraryItem(
    id: 'song',
    name: 'Sour Times',
    kind: ItemKind.song,
    indexNumber: 2,
    discNumber: 1,
    duration: Duration(minutes: 4, seconds: 11),
    albumName: 'Dummy',
    artists: [
      ArtistRef(id: 'a', name: 'Portishead'),
      ArtistRef(id: 'b', name: 'Beth Gibbons'),
    ],
    externalIds: {
      ExternalIdProvider.musicBrainzRecording: recording,
      ExternalIdProvider.musicBrainzTrack: track,
      ExternalIdProvider.musicBrainzArtist: '$artistA; $artistB',
    },
  );

  final listen = Listen(
    song: song,
    album: album,
    listenedAt: DateTime.utc(2026, 9, 20, 12, 30),
  );

  Map<String, Object?> metadata(Map<String, Object?> payload) =>
      payload['track_metadata']! as Map<String, Object?>;

  Map<String, Object?> info(Map<String, Object?> payload) =>
      metadata(payload)['additional_info']! as Map<String, Object?>;

  test('builds a listen with names, timing and MusicBrainz ids', () {
    final payload = listenBrainzPayload(listen, clientVersion: '1.2.3');

    expect(payload['listened_at'], 1789907400);
    expect(metadata(payload)['artist_name'], 'Portishead, Beth Gibbons');
    expect(metadata(payload)['track_name'], 'Sour Times');
    expect(metadata(payload)['release_name'], 'Dummy');
    expect(info(payload), {
      'media_player': listenBrainzClientName,
      'media_player_version': '1.2.3',
      'submission_client': listenBrainzClientName,
      'submission_client_version': '1.2.3',
      'duration_ms': 251000,
      'tracknumber': 2,
      'discnumber': 1,
      'artist_mbids': [artistA, artistB],
      'recording_mbid': recording,
      'track_mbid': track,
      'release_mbid': release,
      'release_group_mbid': group,
    });
  });

  test('now playing payloads carry no timestamp', () {
    final payload = listenBrainzPayload(
      listen,
      clientVersion: '1',
      withTimestamp: false,
    );
    expect(payload.containsKey('listened_at'), isFalse);
  });

  test('falls back to the album artist and drops malformed ids', () {
    const bare = LibraryItem(
      id: 'bare',
      name: 'Untitled',
      kind: ItemKind.song,
      externalIds: {
        ExternalIdProvider.musicBrainzRecording: 'not-a-uuid',
        ExternalIdProvider.musicBrainzArtist: '',
      },
    );
    final payload = listenBrainzPayload(
      Listen(song: bare, album: album, listenedAt: listen.listenedAt),
      clientVersion: '1',
    );

    expect(metadata(payload)['artist_name'], 'Portishead');
    expect(metadata(payload)['release_name'], 'Dummy');
    expect(info(payload).containsKey('recording_mbid'), isFalse);
    expect(info(payload)['artist_mbids'], [artistA]);
    expect(info(payload)['release_mbid'], release);
    expect(info(payload).containsKey('duration_ms'), isFalse);
    expect(info(payload).containsKey('tracknumber'), isFalse);
  });

  test('musicBrainzIds splits lists and normalises case', () {
    expect(
      musicBrainzIds('${artistA.toUpperCase()} / $artistB, junk'),
      [artistA, artistB],
    );
    expect(musicBrainzIds(null), isEmpty);
  });
}
