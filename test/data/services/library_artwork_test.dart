import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:jplayer/src/data/services/library_artwork.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  const library = LibraryItem(id: 'lib', name: 'Music', kind: ItemKind.library);

  test(
    '- keys a cover the way its server caches it while that server is active',
    () {
      const url = 'http://100.64.0.9:8096/Items/lib/Images/Primary?tag=1';
      final saved = savedLibraries(
        [library],
        imageOf: (_) => Uri.parse(url),
        addresses: ['http://192.168.1.9:8096', 'http://100.64.0.9:8096'],
      ).single;

      const whileActive = ArtworkRoute(
        addresses: ['http://192.168.1.9:8096', 'http://100.64.0.9:8096'],
      );
      expect(saved.imageUrl, url);
      expect(saved.imageKey, whileActive.keyFor(url));
      expect(saved.imageKey, '/Items/lib/Images/Primary?tag=1');
    },
  );

  test('- keeps a library without a network cover', () {
    final saved = savedLibraries(
      [library],
      imageOf: (_) => Uri.file('/covers/lib.jpg'),
      addresses: const ['http://a.local'],
    ).single;

    expect(saved.id, 'lib');
    expect(saved.imageUrl, isNull);
    expect(saved.imageKey, isNull);
  });
}
