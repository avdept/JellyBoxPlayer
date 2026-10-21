import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/utils/release_type_sections.dart';

LibraryItem album(String id, {List<String> releaseTypes = const []}) =>
    LibraryItem(
      id: id,
      name: id,
      kind: ItemKind.album,
      releaseTypes: releaseTypes,
    );

void main() {
  test('albums without release types form a single plain section', () {
    final sections = releaseTypeSections([album('a'), album('b')]);

    expect(sections.single.label, 'Albums');
    expect(sections.single.albums.map((a) => a.id), ['a', 'b']);
  });

  test('groups by type combination and keeps the plain section first', () {
    final sections = releaseTypeSections([
      album('live', releaseTypes: ['Album', 'Live']),
      album('soundtrack', releaseTypes: ['Single', 'Soundtrack']),
      album('plain', releaseTypes: ['Album']),
      album('untyped'),
      album('ep', releaseTypes: ['EP']),
    ]);

    expect(sections.map((s) => s.label), [
      'Albums',
      'Albums – Live',
      'EPs',
      'Singles – Soundtrack',
    ]);
    expect(sections.first.albums.map((a) => a.id), ['plain', 'untyped']);
  });

  test('matches types case-insensitively', () {
    final sections = releaseTypeSections([
      album('tagged', releaseTypes: ['Album']),
      album('inferred', releaseTypes: ['album']),
      album('live', releaseTypes: ['album', 'live']),
    ]);

    expect(sections.map((s) => s.label), ['Albums', 'Albums – Live']);
    expect(sections.first.albums.map((a) => a.id), ['tagged', 'inferred']);
  });

  test('secondary-only types fall under the album primary', () {
    final sections = releaseTypeSections([
      album('live', releaseTypes: ['Live']),
    ]);

    expect(sections.single.label, 'Albums – Live');
  });

  test('preserves the incoming order inside a section', () {
    final sections = releaseTypeSections([
      album('newer', releaseTypes: ['Album']),
      album('older', releaseTypes: ['Album']),
    ]);

    expect(sections.single.albums.map((a) => a.id), ['newer', 'older']);
  });
}
