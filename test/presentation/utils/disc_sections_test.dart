import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/utils/disc_sections.dart';

LibraryItem _song(String id, {required int track, int? disc}) => LibraryItem(
  id: id,
  name: id,
  kind: ItemKind.song,
  discNumber: disc,
  indexNumber: track,
);

void main() {
  group('compareAlbumOrder', () {
    test('orders by disc first, then by track number', () {
      final songs = [
        _song('d2t1', disc: 2, track: 1),
        _song('d1t2', disc: 1, track: 2),
        _song('d1t1', disc: 1, track: 1),
        _song('d2t3', disc: 2, track: 3),
      ]..sort(LibraryItem.compareAlbumOrder);

      expect(songs.map((s) => s.id), ['d1t1', 'd1t2', 'd2t1', 'd2t3']);
    });

    test('songs without a disc number come before numbered discs', () {
      final songs = [
        _song('d1t1', disc: 1, track: 1),
        _song('t5', track: 5),
        _song('t2', track: 2),
      ]..sort(LibraryItem.compareAlbumOrder);

      expect(songs.map((s) => s.id), ['t2', 't5', 'd1t1']);
    });
  });

  group('discSections', () {
    test('groups consecutive songs by disc number', () {
      final sections = discSections([
        _song('d1t1', disc: 1, track: 1),
        _song('d1t2', disc: 1, track: 2),
        _song('d2t1', disc: 2, track: 1),
      ]);

      expect(sections.map((s) => s.discNumber), [1, 2]);
      expect(sections[0].songs.map((s) => s.id), ['d1t1', 'd1t2']);
      expect(sections[1].songs.map((s) => s.id), ['d2t1']);
    });

    test('single-disc album yields one section', () {
      final sections = discSections([
        _song('t1', disc: 1, track: 1),
        _song('t2', disc: 1, track: 2),
      ]);

      expect(sections, hasLength(1));
    });

    test('empty list yields no sections', () {
      expect(discSections([]), isEmpty);
    });
  });

  test('discNumber survives the JSON round trip', () {
    final item = _song('x', disc: 3, track: 4);
    expect(LibraryItem.fromJson(item.toJson()).discNumber, 3);
    expect(
      LibraryItem.fromJson(_song('y', track: 1).toJson()).discNumber,
      isNull,
    );
  });
}
