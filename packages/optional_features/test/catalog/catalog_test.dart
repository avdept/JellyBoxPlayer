import 'package:optional_features/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('the stub installs no catalog sources', () {
    expect(catalogSources(), isEmpty);
  });

  test('models round-trip through json with their additional data', () {
    final album = CatalogAlbum(
      source: 'test',
      id: '7',
      title: 'Kid A',
      releaseType: CatalogReleaseType.ep,
      releaseDate: DateTime(2000, 10, 2),
      url: Uri.parse('https://example.com/album/7'),
      additionalData: const {'label': 'Parlophone', 'tracks': 10},
    );

    final copy = CatalogAlbum.fromJson(album.toJson());

    expect(copy.key, album.key);
    expect(copy.releaseType, CatalogReleaseType.ep);
    expect(copy.releaseDate, DateTime(2000, 10, 2));
    expect(copy.url, album.url);
    expect(copy.additionalData, {'label': 'Parlophone', 'tracks': 10});
  });

  test('normalizeCatalogName ignores case, punctuation and ampersands', () {
    expect(
      normalizeCatalogName('Simon & Garfunkel'),
      normalizeCatalogName('simon and garfunkel'),
    );
    expect(normalizeCatalogName('AC/DC'), 'acdc');
    expect(normalizeCatalogName('Sigur Rós'), 'sigurrós');
  });
}
