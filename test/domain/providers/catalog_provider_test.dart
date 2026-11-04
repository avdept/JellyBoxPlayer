import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/catalog_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

void main() {
  late MockMediaServerClient client;

  LibraryItem artist(String id, String name) =>
      LibraryItem(id: id, name: name, kind: ItemKind.artist);

  setUpAll(() => registerFallbackValue(const SearchQuery(term: '')));

  setUp(() => client = MockMediaServerClient());

  void searchReturns(List<LibraryItem> items) => when(
    () => client.searchArtists(any()),
  ).thenAnswer((_) async => LibraryPage(items: items));

  group('libraryArtistNamed', () {
    test('matches the same name written differently', () async {
      searchReturns([
        artist('1', 'Simon & Garfunkel Tribute'),
        artist('2', 'Simon and Garfunkel'),
      ]);

      final match = await libraryArtistNamed(client, 'Simon & Garfunkel');

      expect(match?.id, '2');
    });

    test('does not treat a partial name as the artist', () async {
      searchReturns([artist('1', 'Radiohead Tribute')]);

      expect(await libraryArtistNamed(client, 'Radiohead'), isNull);
    });

    test('a failing search reads as not in the library', () async {
      when(
        () => client.searchArtists(any()),
      ).thenThrow(Exception('offline'));

      expect(await libraryArtistNamed(client, 'Radiohead'), isNull);
    });
  });

  group('missingAlbums', () {
    CatalogAlbum album(
      String id,
      String title, {
      CatalogReleaseType type = CatalogReleaseType.album,
      int? year,
    }) => CatalogAlbum(
      source: 'test',
      id: id,
      title: title,
      releaseType: type,
      releaseDate: year == null ? null : DateTime(year),
    );

    test('drops albums the library already has, ignoring punctuation', () {
      final missing = missingAlbums(
        [album('1', 'OK Computer'), album('2', 'In Rainbows!')],
        ownedTitles: ['ok computer'],
      );

      expect(missing.map((a) => a.id), ['2']);
    });

    test('an edition suffix still counts as the owned album', () {
      final missing = missingAlbums(
        [
          album('1', 'Kid A (Deluxe Edition)'),
          album('2', 'Amnesiac [Remastered]'),
        ],
        ownedTitles: ['Kid A'],
      );

      expect(missing.map((a) => a.id), ['2']);
    });

    test('keeps only albums and EPs, one per title, newest first', () {
      final missing = missingAlbums(
        [
          album('1', 'Creep', type: CatalogReleaseType.single, year: 1992),
          album('2', 'Pablo Honey', year: 1993),
          album('3', 'Pablo Honey (Japan Edition)', year: 1994),
          album('4', 'Drill', type: CatalogReleaseType.ep, year: 1992),
          album('5', 'Best Of', type: CatalogReleaseType.compilation),
          album('6', 'Undated'),
        ],
        ownedTitles: const [],
      );

      expect(missing.map((a) => a.id), ['2', '4', '6']);
    });
  });
}
