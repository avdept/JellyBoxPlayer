import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_query.dart';
import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

void main() {
  test('album list types follow the browse sort', () {
    expect(subsonicAlbumListType(ItemSort.name), 'alphabeticalByName');
    expect(subsonicAlbumListType(ItemSort.albumArtist), 'alphabeticalByArtist');
    expect(subsonicAlbumListType(ItemSort.dateCreated), 'newest');
    expect(subsonicAlbumListType(ItemSort.random), 'random');
    expect(subsonicAlbumListType(ItemSort.datePlayed), 'recent');
    expect(subsonicAlbumListType(ItemSort.playCount), 'frequent');
    expect(subsonicAlbumListType(ItemSort.releaseDate), 'alphabeticalByName');
  });

  group('pages', () {
    final items = [
      for (var i = 0; i < 5; i++)
        LibraryItem(id: '$i', name: '$i', kind: ItemKind.album),
    ];

    test('- slice whole lists and report the real total', () {
      final page = subsonicPageOf(items, startIndex: 2, limit: 2);
      expect(page.items.map((i) => i.id), ['2', '3']);
      expect(page.totalRecordCount, 5);
    });

    test('- report an open-ended total for server-paged lists', () {
      final page = subsonicOpenPage(items.take(3).toList(), startIndex: 100);
      expect(page.totalRecordCount, 103);
    });
  });

  group('client-side sorting', () {
    final albums = [
      SubsonicAlbumDTO(
        id: 'b',
        name: 'Beta',
        year: 2001,
        created: DateTime.utc(2026, 1, 2),
      ),
      SubsonicAlbumDTO(
        id: 'a',
        name: 'alpha',
        year: 2010,
        created: DateTime.utc(2026, 1, 3),
      ),
      const SubsonicAlbumDTO(id: 'c', name: 'Gamma'),
    ];

    test('- orders albums by name case-insensitively', () {
      final sorted = subsonicSortAlbums(
        albums,
        ItemSort.name,
        SortDirection.ascending,
      );
      expect(sorted.map((a) => a.id), ['a', 'b', 'c']);
    });

    test('- orders albums by date added with unknown dates last', () {
      final sorted = subsonicSortAlbums(
        albums,
        ItemSort.dateCreated,
        SortDirection.descending,
      );
      expect(sorted.map((a) => a.id), ['c', 'a', 'b']);
    });

    test('- orders albums by release year', () {
      final sorted = subsonicSortAlbums(
        albums,
        ItemSort.releaseDate,
        SortDirection.ascending,
      );
      expect(sorted.map((a) => a.id), ['b', 'a', 'c']);
    });

    test('- shuffles deterministically for random', () {
      final first = subsonicSortAlbums(
        albums,
        ItemSort.random,
        SortDirection.ascending,
        random: Random(7),
      );
      final second = subsonicSortAlbums(
        albums,
        ItemSort.random,
        SortDirection.ascending,
        random: Random(7),
      );
      expect(first.map((a) => a.id), second.map((a) => a.id));
      expect(first.map((a) => a.id).toSet(), {'a', 'b', 'c'});
    });

    test('- orders playlists by last change', () {
      final playlists = [
        SubsonicPlaylistDTO(id: 'old', changed: DateTime.utc(2026, 1, 1)),
        SubsonicPlaylistDTO(id: 'new', changed: DateTime.utc(2026, 2, 1)),
      ];
      final sorted = subsonicSortPlaylists(
        playlists,
        ItemSort.dateLastContentAdded,
        SortDirection.descending,
      );
      expect(sorted.map((p) => p.id), ['new', 'old']);
    });

    test('- keeps album order for songs when asked for it', () {
      final songs = [
        const SubsonicChildDTO(id: 'z', title: 'Zed'),
        const SubsonicChildDTO(id: 'a', title: 'Ay'),
      ];
      expect(
        subsonicSortSongs(
          songs,
          ItemSort.albumOrder,
          SortDirection.ascending,
        ).map((s) => s.id),
        ['z', 'a'],
      );
      expect(
        subsonicSortSongs(
          songs,
          ItemSort.name,
          SortDirection.ascending,
        ).map((s) => s.id),
        ['a', 'z'],
      );
    });
  });

  test('album order sorts by disc then track', () {
    final songs = [
      const SubsonicChildDTO(id: '2-1', discNumber: 2, track: 1),
      const SubsonicChildDTO(id: '1-2', discNumber: 1, track: 2),
      const SubsonicChildDTO(id: '1-1', discNumber: 1, track: 1),
      const SubsonicChildDTO(id: 'none'),
    ];
    expect(subsonicAlbumOrder(songs).map((s) => s.id), [
      'none',
      '1-1',
      '1-2',
      '2-1',
    ]);
  });

  test('played filters use the play count', () {
    final songs = [
      const SubsonicChildDTO(id: 'played', playCount: 2),
      const SubsonicChildDTO(id: 'fresh'),
    ];
    expect(
      subsonicFilterSongs(songs, {ItemFilterFlag.played}).map((s) => s.id),
      ['played'],
    );
    expect(
      subsonicFilterSongs(songs, {ItemFilterFlag.unplayed}).map((s) => s.id),
      ['fresh'],
    );
    expect(subsonicFilterSongs(songs, {ItemFilterFlag.favorite}), songs);
  });
}
