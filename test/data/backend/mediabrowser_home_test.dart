import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/mediabrowser_home.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:mocktail/mocktail.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  late MockMediaServerClient client;

  setUpAll(() {
    registerFallbackValue(const LibraryQuery());
  });

  setUp(() {
    client = MockMediaServerClient();
  });

  LibraryItem song(String id, String albumId, {int plays = 1}) => LibraryItem(
    id: id,
    name: id,
    kind: ItemKind.song,
    albumId: albumId,
    userData: PlaybackUserData(playCount: plays, played: true),
  );

  LibraryItem album(String id) =>
      LibraryItem(id: id, name: id, kind: ItemKind.album);

  void stubAlbums(List<String> ids) {
    when(
      () => client.getAlbums(
        any(
          that: predicate<LibraryQuery>(
            (q) => q.ids.isNotEmpty,
          ),
        ),
      ),
    ).thenAnswer(
      (invocation) async {
        final query = invocation.positionalArguments.single as LibraryQuery;
        return LibraryPage(
          items: [
            for (final id in query.ids.reversed)
              if (ids.contains(id)) album(id),
          ],
          totalRecordCount: ids.length,
        );
      },
    );
  }

  group('mediaBrowserRecentlyPlayedAlbums', () {
    test(
      '- scans played songs by last-played date and keeps first-seen album order',
      () async {
        when(() => client.getAllSongs(any())).thenAnswer(
          (_) async => LibraryPage(
            items: [
              song('s1', 'a2'),
              song('s2', 'a1'),
              song('s3', 'a2'),
              song('s4', 'a3'),
            ],
          ),
        );
        stubAlbums(['a1', 'a2', 'a3']);

        final albums = await mediaBrowserRecentlyPlayedAlbums(
          client,
          libraryId: 'lib-1',
          limit: 2,
        );

        expect(albums.map((a) => a.id), ['a2', 'a1']);
        final query =
            verify(() => client.getAllSongs(captureAny())).captured.single
                as LibraryQuery;
        expect(query.sort, ItemSort.datePlayed);
        expect(query.direction, SortDirection.descending);
        expect(query.filters, {ItemFilterFlag.played});
        expect(query.libraryId, 'lib-1');
        expect(query.limit, mediaBrowserPlayedSongsScanLimit);
      },
    );

    test('- drops albums the server no longer returns', () async {
      when(() => client.getAllSongs(any())).thenAnswer(
        (_) async => LibraryPage(items: [song('s1', 'gone'), song('s2', 'a1')]),
      );
      stubAlbums(['a1']);

      final albums = await mediaBrowserRecentlyPlayedAlbums(client, limit: 5);

      expect(albums.map((a) => a.id), ['a1']);
    });

    test('- skips the album lookup when nothing was played', () async {
      when(
        () => client.getAllSongs(any()),
      ).thenAnswer((_) async => const LibraryPage());

      final albums = await mediaBrowserRecentlyPlayedAlbums(client, limit: 5);

      expect(albums, isEmpty);
      verifyNever(() => client.getAlbums(any()));
    });
  });

  group('mediaBrowserMostPlayedAlbums', () {
    test('- ranks albums by summed song play counts', () async {
      when(() => client.getAllSongs(any())).thenAnswer(
        (_) async => LibraryPage(
          items: [
            song('s1', 'a1', plays: 2),
            song('s2', 'a2', plays: 5),
            song('s3', 'a1', plays: 4),
            song('s4', 'a3', plays: 1),
          ],
        ),
      );
      stubAlbums(['a1', 'a2', 'a3']);

      final albums = await mediaBrowserMostPlayedAlbums(client, limit: 2);

      expect(albums.map((a) => a.id), ['a1', 'a2']);
      final query =
          verify(() => client.getAllSongs(captureAny())).captured.single
              as LibraryQuery;
      expect(query.sort, ItemSort.playCount);
      expect(query.direction, SortDirection.descending);
      expect(query.filters, {ItemFilterFlag.played});
    });
  });
}
