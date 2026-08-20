import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/playlist_generation.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  LibraryItem song(
    String id, {
    String? album,
    int plays = 0,
    bool hasImage = false,
  }) => LibraryItem(
    id: id,
    name: id,
    kind: ItemKind.song,
    albumId: album,
    images: hasImage ? ImageRefs(albumPrimary: 'tag-$id') : const ImageRefs(),
    userData: PlaybackUserData(playCount: plays, played: plays > 0),
  );

  List<LibraryItem> blend({
    required int familiarCount,
    required int freshCount,
    required int seed,
    String Function(int index)? familiarAlbum,
    String Function(int index)? freshAlbum,
  }) => blendSongs(
    familiar: [
      for (var i = 1; i <= familiarCount; i++)
        song('f$i', plays: i, album: familiarAlbum?.call(i)),
    ],
    fresh: [
      for (var i = 1; i <= freshCount; i++)
        song('n$i', album: freshAlbum?.call(i)),
    ],
    random: Random(seed),
  );

  group('genreKey', () {
    test('- collapses punctuation, spacing and case', () {
      expect(genreKey('Alt Metal'), genreKey('Alt. Metal'));
      expect(genreKey('Alt Metal'), genreKey('alt-metal'));
      expect(genreKey('Hip Hop'), genreKey('Hip-Hop'));
      expect(genreKey('Drum & Bass'), genreKey('Drum and Bass'));
    });

    test('- keeps genuinely different genres apart', () {
      expect(genreKey('Alt Metal'), isNot(genreKey('Alternative Metal')));
      expect(genreKey('Death Metal'), isNot(genreKey('Black Metal')));
      expect(genreKey('Pop'), isNot(genreKey('Pop Rock')));
    });
  });

  group('achievablePlaylistLength', () {
    List<LibraryItem> spread({required int albums, required int perAlbum}) => [
      for (var a = 1; a <= albums; a++)
        for (var t = 1; t <= perAlbum; t++) song('a$a-t$t', album: 'album-$a'),
    ];

    test('- counts at most two songs per album', () {
      expect(achievablePlaylistLength(spread(albums: 10, perAlbum: 2)), 20);
      expect(achievablePlaylistLength(spread(albums: 10, perAlbum: 9)), 20);
      expect(achievablePlaylistLength(spread(albums: 30, perAlbum: 1)), 30);
    });

    test('- sees that a one-album genre can only yield two songs', () {
      expect(achievablePlaylistLength(spread(albums: 1, perAlbum: 40)), 2);
    });

    test('- treats a song with no album as its own album', () {
      expect(achievablePlaylistLength([song('a'), song('b'), song('c')]), 3);
    });

    test('- agrees with what blendSongs actually produces', () {
      for (final albums in [1, 2, 5, 9, 10, 20]) {
        final pool = spread(albums: albums, perAlbum: 4);
        final produced = blendSongs(
          familiar: const [],
          fresh: pool,
          random: Random(albums),
        );
        final expected = achievablePlaylistLength(pool);

        expect(
          produced,
          hasLength(
            expected < generatedPlaylistSongLimit
                ? expected
                : generatedPlaylistSongLimit,
          ),
          reason: 'with $albums albums',
        );
      }
    });
  });

  group('pickCoverSongs', () {
    test('- takes one song per album, up to four', () {
      final picks = pickCoverSongs([
        for (var a = 1; a <= 6; a++)
          for (var t = 1; t <= 3; t++)
            song('a$a-t$t', album: 'album-$a', hasImage: true),
      ]);

      expect(picks, hasLength(coverSongCount));
      expect(
        picks.map((item) => item.albumId).toSet(),
        hasLength(coverSongCount),
      );
    });

    test('- skips songs with no artwork', () {
      final picks = pickCoverSongs([
        song('no-art-1', album: 'album-1'),
        song('art-1', album: 'album-2', hasImage: true),
      ]);

      expect(picks.map((item) => item.id), ['art-1']);
    });
  });

  group('blendSongs', () {
    test('- blends four familiar tracks with sixteen fresh ones', () {
      final blended = blend(familiarCount: 20, freshCount: 20, seed: 1);

      expect(blended, hasLength(generatedPlaylistSongLimit));
      expect(blended.where((item) => item.id.startsWith('f')), hasLength(4));
      expect(blended.where((item) => item.id.startsWith('n')), hasLength(16));
    });

    test('- orders the result unpredictably', () {
      final first = blend(familiarCount: 20, freshCount: 20, seed: 1);
      final second = blend(familiarCount: 20, freshCount: 20, seed: 2);

      expect(
        first.map((item) => item.id).toList(),
        isNot(second.map((item) => item.id).toList()),
      );
    });

    test('- tops up to the limit when fresh runs short', () {
      final blended = blend(familiarCount: 20, freshCount: 2, seed: 3);

      expect(blended, hasLength(generatedPlaylistSongLimit));
      expect(blended.where((item) => item.id.startsWith('n')), hasLength(2));
    });

    test('- returns everything it has when both halves are short', () {
      final blended = blend(familiarCount: 3, freshCount: 0, seed: 4);

      expect(blended.map((item) => item.id).toSet(), {'f1', 'f2', 'f3'});
    });

    test('- allows at most two songs from the same album', () {
      final blended = blend(
        familiarCount: 20,
        freshCount: 20,
        seed: 5,
        familiarAlbum: (i) => i <= 8 ? 'album-a' : 'album-f$i',
        freshAlbum: (i) => i <= 6 ? 'album-b' : 'album-n$i',
      );

      final perAlbum = <String, int>{};
      for (final item in blended) {
        perAlbum.update(item.albumId!, (n) => n + 1, ifAbsent: () => 1);
      }

      expect(blended, hasLength(generatedPlaylistSongLimit));
      expect(
        perAlbum.values,
        everyElement(lessThanOrEqualTo(maxSongsPerAlbum)),
      );
      expect(perAlbum['album-a'], maxSongsPerAlbum);
      expect(perAlbum['album-b'], maxSongsPerAlbum);
    });

    test('- counts the album cap across both halves', () {
      final blended = blend(
        familiarCount: 2,
        freshCount: 2,
        seed: 6,
        familiarAlbum: (_) => 'shared',
        freshAlbum: (_) => 'shared',
      );

      expect(blended, hasLength(maxSongsPerAlbum));
      expect(
        blended.every((item) => item.albumId == 'shared'),
        isTrue,
      );
    });
  });
}
