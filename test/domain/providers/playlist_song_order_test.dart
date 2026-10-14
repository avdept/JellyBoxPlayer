import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playlist_song_order_provider.dart';

LibraryItem _song(
  String id, {
  required String name,
  String artist = '',
  String album = '',
  int track = 0,
}) => LibraryItem(
  id: id,
  name: name,
  kind: ItemKind.song,
  albumArtist: artist,
  albumName: album,
  indexNumber: track,
);

void main() {
  final songs = [
    _song('1', name: 'delta', artist: 'Beta', album: 'Zed', track: 2),
    _song('2', name: 'Alpha', artist: 'alpha', album: 'Ay', track: 1),
    _song('3', name: 'charlie', artist: 'Beta', album: 'Zed', track: 1),
    _song('4', name: 'Bravo', artist: 'alpha', album: 'Ay', track: 2),
  ];

  List<String> ids(List<LibraryItem> items) => [for (final s in items) s.id];

  group('PlaylistSongOrder', () {
    test('- keeps the playlist untouched by default', () {
      expect(ids(const PlaylistSongOrder().apply(songs)), ['1', '2', '3', '4']);
    });

    test('- reverses the playlist order when flipped', () {
      const order = PlaylistSongOrder(descending: true);
      expect(ids(order.apply(songs)), ['4', '3', '2', '1']);
    });

    test('- sorts titles ignoring case', () {
      const order = PlaylistSongOrder(sort: PlaylistSongSort.title);
      expect(ids(order.apply(songs)), ['2', '4', '3', '1']);
    });

    test('- keeps playlist order among songs by the same artist', () {
      const order = PlaylistSongOrder(sort: PlaylistSongSort.artist);
      expect(ids(order.apply(songs)), ['2', '4', '1', '3']);
    });

    test('- groups by album and follows track order inside it', () {
      const order = PlaylistSongOrder(sort: PlaylistSongSort.album);
      expect(ids(order.apply(songs)), ['2', '4', '3', '1']);
    });

    test('- picking the same sort again flips its direction', () {
      final once = const PlaylistSongOrder().select(PlaylistSongSort.title);
      expect(once.sort, PlaylistSongSort.title);
      expect(once.descending, isFalse);

      final twice = once.select(PlaylistSongSort.title);
      expect(twice.descending, isTrue);
      expect(ids(twice.apply(songs)), ['1', '3', '4', '2']);

      final other = twice.select(PlaylistSongSort.album);
      expect(other.sort, PlaylistSongSort.album);
      expect(other.descending, isFalse);
    });
  });
}
