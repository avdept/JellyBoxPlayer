import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playlist_song_filter.dart';

LibraryItem _song(
  String id, {
  required String name,
  String artist = '',
  String album = '',
}) => LibraryItem(
  id: id,
  name: name,
  kind: ItemKind.song,
  albumArtist: artist,
  albumName: album,
);

void main() {
  final songs = [
    _song('1', name: 'Blue Monday', artist: 'New Order', album: 'Power'),
    _song('2', name: 'Monday Morning', artist: 'Fleetwood Mac', album: 'FM'),
    _song('3', name: 'Ceremony', artist: 'New Order', album: 'Substance'),
    _song('4', name: 'Temptation', artist: 'Heaven 17', album: 'The Luxury'),
  ];

  List<String> ids(List<LibraryItem> items) => [for (final s in items) s.id];

  group('filterSongsByQuery', () {
    test('- returns the same list for an empty or blank query', () {
      expect(filterSongsByQuery(songs, ''), same(songs));
      expect(filterSongsByQuery(songs, '   '), same(songs));
    });

    test('- matches title, artist and album ignoring case', () {
      expect(ids(filterSongsByQuery(songs, 'monday')), ['1', '2']);
      expect(ids(filterSongsByQuery(songs, 'NEW ORDER')), ['1', '3']);
      expect(ids(filterSongsByQuery(songs, 'luxury')), ['4']);
    });

    test('- requires every term to match somewhere', () {
      expect(ids(filterSongsByQuery(songs, 'monday order')), ['1']);
      expect(ids(filterSongsByQuery(songs, 'monday  substance')), isEmpty);
    });

    test('- keeps the incoming order', () {
      expect(ids(filterSongsByQuery(songs.reversed.toList(), 'order')), [
        '3',
        '1',
      ]);
    });
  });
}
