import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/android_auto/auto_media_id.dart';

void main() {
  group('AutoMediaId', () {
    test('- round-trips plain nodes', () {
      for (final type in [
        AutoMediaId.root,
        AutoMediaId.recent,
        AutoMediaId.home,
        AutoMediaId.library,
        AutoMediaId.downloads,
        AutoMediaId.signIn,
        AutoMediaId.resume,
        AutoMediaId.albums,
        AutoMediaId.artists,
        AutoMediaId.playlists,
        AutoMediaId.songs,
      ]) {
        final id = AutoMediaId(type);
        expect(id.encode(), type);
        expect(AutoMediaId.parse(type), id);
      }
    });

    test('- round-trips ids with reserved characters', () {
      const id = AutoMediaId(AutoMediaId.mix, id: 'jellybox:liked-songs');
      final encoded = id.encode();
      expect(encoded, 'mix/jellybox%3Aliked-songs');
      expect(AutoMediaId.parse(encoded), id);
    });

    test('- carries paging and song context in the query', () {
      const paged = AutoMediaId(AutoMediaId.albums, start: 200);
      expect(paged.encode(), 'albums?start=200');
      expect(AutoMediaId.parse('albums?start=200'), paged);

      const song = AutoMediaId(
        AutoMediaId.song,
        id: 's1',
        context: 'album:a b',
      );
      final encoded = song.encode();
      expect(encoded, 'song/s1?ctx=album%3Aa+b');
      expect(AutoMediaId.parse(encoded), song);
    });

    test('- encodes play-all nodes as a nested path', () {
      const all = AutoMediaId(AutoMediaId.artist, id: 'ar1', playAll: true);
      expect(all.encode(), 'artist/ar1/all');
      expect(AutoMediaId.parse('artist/ar1/all'), all);
      expect(
        const AutoMediaId(AutoMediaId.album, id: 'a1').all.encode(),
        'album/a1/all',
      );
      expect(
        AutoMediaId.parse('mix/jellybox%3Aliked-songs/all'),
        const AutoMediaId(
          AutoMediaId.mix,
          id: 'jellybox:liked-songs',
          playAll: true,
        ),
      );
      expect(AutoMediaId.parse('song/s1/all'), isNull);
    });

    test('- withStart keeps everything else', () {
      const id = AutoMediaId(AutoMediaId.artist, id: 'ar1');
      expect(id.withStart(100).encode(), 'artist/ar1?start=100');
    });

    test('- rejects unknown or malformed ids', () {
      for (final raw in [
        '',
        'nope',
        'album',
        'album/',
        'artist/ar1/nope',
        'a/b/c/d',
        'albums?start=-5',
        'root/x',
      ]) {
        expect(AutoMediaId.parse(raw), isNull, reason: raw);
      }
    });
  });
}
