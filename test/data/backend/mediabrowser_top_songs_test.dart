import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_client.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/mediabrowser_top_songs.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  late MockMediaServerClient client;
  late MockHttpClientAdapter adapter;
  late ListenBrainzClient listenBrainz;

  setUpAll(() {
    registerFallbackValue(const LibraryQuery());
    registerFallbackValue(RequestOptions());
  });

  setUp(() {
    client = MockMediaServerClient();
    adapter = MockHttpClientAdapter();
    listenBrainz = ListenBrainzClient()..dio.httpClientAdapter = adapter;
  });

  LibraryItem artist({String? mbid}) => LibraryItem(
    id: 'artist-1',
    name: 'Portishead',
    kind: ItemKind.artist,
    externalIds: {ExternalIdProvider.musicBrainzArtist: ?mbid},
  );

  LibraryItem song(String id, {int plays = 0, String? mbid}) => LibraryItem(
    id: id,
    name: id,
    kind: ItemKind.song,
    userData: PlaybackUserData(playCount: plays, played: plays > 0),
    externalIds: {ExternalIdProvider.musicBrainzRecording: ?mbid},
  );

  void stubSongs(List<LibraryItem> songs) =>
      when(() => client.getSongsOfSet(any())).thenAnswer(
        (_) async => LibraryPage(items: songs, totalRecordCount: songs.length),
      );

  void stubListenBrainz(int status, Object body) =>
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

  List<Map<String, Object?>> recordings(List<String> mbids) => [
    for (final mbid in mbids) {'recording_mbid': mbid, 'recording_name': mbid},
  ];

  test('- asks for the artist songs by play count with id and sort', () async {
    stubSongs([]);

    await mediaBrowserTopSongs(
      client,
      artist(),
      listenBrainz: listenBrainz,
      limit: 10,
    );

    final query =
        verify(() => client.getSongsOfSet(captureAny())).captured.single
            as LibraryQuery;
    expect(query.artistIds, ['artist-1']);
    expect(query.sort, ItemSort.playCount);
    expect(query.direction, SortDirection.descending);
    expect(query.limit, mediaBrowserTopSongsScanLimit);
    verifyNever(() => adapter.fetch(any(), any(), any()));
  });

  test(
    '- ranks by ListenBrainz when the artist has a MusicBrainz id',
    () async {
      stubSongs([
        song('s1', plays: 9, mbid: 'mb-1'),
        song('s2', mbid: 'mb-2'),
        song('s3', mbid: 'mb-3'),
      ]);
      stubListenBrainz(200, recordings(['mb-3', 'mb-2', 'mb-1']));

      final songs = await mediaBrowserTopSongs(
        client,
        artist(mbid: 'artist-mbid'),
        listenBrainz: listenBrainz,
        limit: 2,
      );

      expect(songs.map((song) => song.id), ['s3', 's2']);
      final request =
          verify(
                () => adapter.fetch(captureAny(), any(), any()),
              ).captured.single
              as RequestOptions;
      expect(
        request.uri.path,
        '/1/popularity/top-recordings-for-artist/artist-mbid',
      );
    },
  );

  test(
    '- falls back to the user play counts without a MusicBrainz id',
    () async {
      stubSongs([
        for (var i = 1; i <= 6; i++) song('s$i', plays: i),
        song('never-played'),
      ]);

      final songs = await mediaBrowserTopSongs(
        client,
        artist(),
        listenBrainz: listenBrainz,
        limit: 3,
      );

      expect(songs.map((song) => song.id), ['s6', 's5', 's4']);
      verifyNever(() => adapter.fetch(any(), any(), any()));
    },
  );

  test('- falls back to play counts when ListenBrainz fails', () async {
    stubSongs([for (var i = 1; i <= 5; i++) song('s$i', plays: i)]);
    stubListenBrainz(503, {'error': 'down'});

    final songs = await mediaBrowserTopSongs(
      client,
      artist(mbid: 'artist-mbid'),
      listenBrainz: listenBrainz,
      limit: 10,
    );

    expect(songs.map((song) => song.id), ['s5', 's4', 's3', 's2', 's1']);
  });

  test(
    '- falls back to play counts when nothing in the library matches',
    () async {
      stubSongs([for (var i = 1; i <= 5; i++) song('s$i', plays: i)]);
      stubListenBrainz(200, recordings(['mb-other']));

      final songs = await mediaBrowserTopSongs(
        client,
        artist(mbid: 'artist-mbid'),
        listenBrainz: listenBrainz,
        limit: 10,
      );

      expect(songs, hasLength(5));
    },
  );

  test('- hides the section when too few songs have been played', () async {
    stubSongs([
      for (var i = 1; i <= mediaBrowserTopSongsMinimumPlayed - 1; i++)
        song('s$i', plays: i),
      song('never-played'),
    ]);

    final songs = await mediaBrowserTopSongs(
      client,
      artist(),
      listenBrainz: listenBrainz,
      limit: 10,
    );

    expect(songs, isEmpty);
  });
}
