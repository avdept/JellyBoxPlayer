import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/android_auto/auto_media_id.dart';

void main() {
  group('AutoMediaId', () {
    test('- round-trips every id shape', () {
      const ids = [
        AutoMediaId(AutoMediaId.root),
        AutoMediaId(AutoMediaId.albums, start: 200),
        AutoMediaId(AutoMediaId.mix, id: 'jellybox:liked-songs'),
        AutoMediaId(AutoMediaId.album, id: 'a1', playAll: true),
        AutoMediaId(AutoMediaId.song, id: 's1', context: 'album:a b'),
      ];
      for (final id in ids) {
        expect(AutoMediaId.parse(id.encode()), id, reason: id.encode());
      }
      expect(
        const AutoMediaId(AutoMediaId.mix, id: 'jellybox:liked-songs').encode(),
        'mix/jellybox%3Aliked-songs',
      );
      expect(
        const AutoMediaId(
          AutoMediaId.artist,
          id: 'ar1',
        ).withStart(100).encode(),
        'artist/ar1?start=100',
      );
    });

    test('- rejects unknown or malformed ids', () {
      for (final raw in [
        '',
        'nope',
        'album',
        'album/',
        'song/s1/all',
        'a/b/c/d',
        'albums?start=-5',
        'root/x',
      ]) {
        expect(AutoMediaId.parse(raw), isNull, reason: raw);
      }
    });
  });
}
