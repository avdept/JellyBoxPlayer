import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/musicbrainz/cover_art_finder.dart';
import 'package:jplayer/src/core/musicbrainz/musicbrainz_client.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  const release = '84ee55c7-a600-47d2-a90c-0c18797b8640';
  const groupId = '48140466-cff6-3222-bd55-63c27e43190d';
  const archive = 'https://coverartarchive.org';

  late MockHttpClientAdapter adapter;
  late Map<String, int> covers;
  late List<Map<String, Object?>> searchResults;
  late List<Uri> requests;

  setUpAll(() => registerFallbackValue(RequestOptions()));

  setUp(() {
    adapter = MockHttpClientAdapter();
    covers = {};
    searchResults = [];
    requests = [];
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((call) async {
      final options = call.positionalArguments.first as RequestOptions;
      requests.add(options.uri);
      if (options.uri.host == 'musicbrainz.org') {
        return ResponseBody.fromString(
          jsonEncode({'release-groups': searchResults}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString('', covers[options.uri.path] ?? 404);
    });
  });

  CoverArtFinder build() {
    final musicBrainz = MusicBrainzClient(
      userAgent: 'JellyBox/test (https://example.com)',
      wait: (_) async {},
    )..dio.httpClientAdapter = adapter;
    return CoverArtFinder(
      musicBrainz: musicBrainz,
      userAgent: 'JellyBox/test (https://example.com)',
    )..dio.httpClientAdapter = adapter;
  }

  Iterable<Uri> searches() =>
      requests.where((uri) => uri.host == 'musicbrainz.org');

  group('find', () {
    test('uses the cover of the tagged release without searching', () async {
      covers['/release/$release/front-500'] = 307;

      final cover = await build().find(
        const CoverArtQuery(
          releaseId: release,
          releaseGroupId: groupId,
          artist: 'Portishead',
          album: 'Dummy',
        ),
      );

      expect(cover, '$archive/release/$release/front-500');
      expect(requests, hasLength(1));
    });

    test('falls back to the release group when the release has none', () async {
      covers['/release-group/$groupId/front-500'] = 307;

      final cover = await build().find(
        const CoverArtQuery(releaseId: release, releaseGroupId: groupId),
      );

      expect(cover, '$archive/release-group/$groupId/front-500');
    });

    test('does not search by name when the tagged group has none', () async {
      final cover = await build().find(
        const CoverArtQuery(
          releaseGroupId: groupId,
          artist: 'Portishead',
          album: 'Dummy',
        ),
      );

      expect(cover, isNull);
      expect(searches(), isEmpty);
    });

    test('searches by artist and album when nothing is tagged', () async {
      searchResults = [
        {'id': groupId, 'title': 'Dummy'},
      ];
      covers['/release-group/$groupId/front-500'] = 307;

      final cover = await build().find(
        const CoverArtQuery(artist: 'Portishead', album: 'Dummy'),
      );

      expect(cover, '$archive/release-group/$groupId/front-500');
      expect(
        searches().single.queryParameters['query'],
        'releasegroup:"Dummy" AND artist:"Portishead"',
      );
    });

    test('escapes quotes in the names it searches for', () async {
      await build().find(
        const CoverArtQuery(artist: r'AC\DC', album: 'The "Best" Of'),
      );

      expect(
        searches().single.queryParameters['query'],
        r'releasegroup:"The \"Best\" Of" AND artist:"AC\\DC"',
      );
    });

    test('ignores a search result whose id is not an MBID', () async {
      searchResults = [
        {'id': '../../evil?x=', 'title': 'Dummy'},
      ];

      final cover = await build().find(
        const CoverArtQuery(artist: 'Portishead', album: 'Dummy'),
      );

      expect(cover, isNull);
      expect(requests.where((uri) => uri.host != 'musicbrainz.org'), isEmpty);
    });

    test('ignores search results with a different title', () async {
      searchResults = [
        {'id': groupId, 'title': 'Dummy (Live at Roseland)'},
      ];
      covers['/release-group/$groupId/front-500'] = 307;

      final cover = await build().find(
        const CoverArtQuery(artist: 'Portishead', album: 'Dummy'),
      );

      expect(cover, isNull);
    });

    test('matches titles regardless of case and punctuation', () async {
      searchResults = [
        {'id': groupId, 'title': 'OK Computer'},
      ];
      covers['/release-group/$groupId/front-500'] = 307;

      final cover = await build().find(
        const CoverArtQuery(artist: 'Radiohead', album: 'ok, computer!'),
      );

      expect(cover, isNotNull);
    });

    test('reports an archive outage instead of calling it a miss', () async {
      covers['/release/$release/front-500'] = 503;

      await expectLater(
        build().find(const CoverArtQuery(releaseId: release)),
        throwsA(isA<CoverArtException>()),
      );
    });
  });

  group('CoverArtQuery.forSong', () {
    const song = LibraryItem(
      id: 'song-1',
      name: 'Sour Times',
      kind: ItemKind.song,
      albumId: 'album-1',
      albumName: 'Dummy',
      albumArtist: 'Portishead',
    );

    test('reads the ids tagged on the song', () {
      final query = CoverArtQuery.forSong(
        song.copyWith(
          externalIds: {
            ExternalIdProvider.musicBrainzAlbum: release,
            ExternalIdProvider.musicBrainzReleaseGroup: groupId,
          },
        ),
      );

      expect(query?.releaseId, release);
      expect(query?.releaseGroupId, groupId);
      expect(query?.key, 'release/$release');
    });

    test('borrows ids from the album the song belongs to', () {
      const album = LibraryItem(
        id: 'album-1',
        name: 'Dummy',
        kind: ItemKind.album,
        externalIds: {ExternalIdProvider.musicBrainzReleaseGroup: groupId},
      );

      expect(
        CoverArtQuery.forSong(song, album: album)?.releaseGroupId,
        groupId,
      );
    });

    test('takes nothing from a playlist or another album', () {
      const ids = {ExternalIdProvider.musicBrainzReleaseGroup: groupId};
      const playlist = LibraryItem(
        id: 'album-1',
        name: 'Mix',
        kind: ItemKind.playlist,
        externalIds: ids,
      );
      const other = LibraryItem(
        id: 'album-2',
        name: 'Third',
        kind: ItemKind.album,
        externalIds: ids,
      );

      for (final album in [playlist, other]) {
        final query = CoverArtQuery.forSong(song, album: album);
        expect(query?.releaseGroupId, isNull);
        expect(query?.album, 'Dummy');
      }
    });

    test('ignores ids that are not MusicBrainz ids', () {
      final query = CoverArtQuery.forSong(
        song.copyWith(
          externalIds: {ExternalIdProvider.musicBrainzAlbum: '../../evil'},
        ),
      );

      expect(query?.releaseId, isNull);
      expect(query?.key, 'name/portishead/dummy');
    });

    test('gives up on a song with neither ids nor an album name', () {
      const loose = LibraryItem(
        id: 'song-9',
        name: 'Untitled',
        kind: ItemKind.song,
      );

      expect(CoverArtQuery.forSong(loose), isNull);
    });
  });
}
