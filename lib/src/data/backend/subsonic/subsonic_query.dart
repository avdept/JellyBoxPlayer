import 'dart:math';

import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

const subsonicByGenreListType = 'byGenre';
const subsonicNewestListType = 'newest';
const subsonicRecentListType = 'recent';
const subsonicFrequentListType = 'frequent';

String subsonicAlbumListType(ItemSort sort) => switch (sort) {
  ItemSort.name => 'alphabeticalByName',
  ItemSort.albumArtist => 'alphabeticalByArtist',
  ItemSort.dateCreated => subsonicNewestListType,
  ItemSort.datePlayed => subsonicRecentListType,
  ItemSort.playCount => subsonicFrequentListType,
  ItemSort.random => 'random',
  ItemSort.releaseDate ||
  ItemSort.dateLastContentAdded ||
  ItemSort.albumOrder => 'alphabeticalByName',
};

LibraryPage subsonicPageOf(
  List<LibraryItem> all, {
  required int startIndex,
  required int limit,
}) => LibraryPage(
  items: all.skip(startIndex).take(limit).toList(),
  totalRecordCount: all.length,
);

LibraryPage subsonicOpenPage(
  List<LibraryItem> items, {
  required int startIndex,
}) => LibraryPage(items: items, totalRecordCount: startIndex + items.length);

int subsonicCompareNames(String? a, String? b) =>
    (a ?? '').toLowerCase().compareTo((b ?? '').toLowerCase());

int _compareNullable<T extends Comparable<T>>(T? a, T? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

List<T> _ordered<T>(
  List<T> items,
  Comparator<T>? compare,
  SortDirection direction, {
  Random? random,
}) {
  if (compare == null) {
    final shuffled = [...items]..shuffle(random);
    return shuffled;
  }
  final sorted = [...items]..sort(compare);
  return direction == SortDirection.descending
      ? sorted.reversed.toList()
      : sorted;
}

List<SubsonicAlbumDTO> subsonicSortAlbums(
  List<SubsonicAlbumDTO> albums,
  ItemSort sort,
  SortDirection direction, {
  Random? random,
}) {
  final compare = subsonicAlbumComparator(sort);
  return _ordered(albums, compare, direction, random: random);
}

List<SubsonicArtistDTO> subsonicSortArtists(
  List<SubsonicArtistDTO> artists,
  ItemSort sort,
  SortDirection direction, {
  Random? random,
}) {
  final compare = subsonicArtistComparator(sort);
  return _ordered(artists, compare, direction, random: random);
}

List<SubsonicGenreDTO> subsonicSortGenres(
  List<SubsonicGenreDTO> genres,
  ItemSort sort,
  SortDirection direction, {
  Random? random,
}) {
  final compare = subsonicGenreComparator(sort);
  return _ordered(genres, compare, direction, random: random);
}

List<SubsonicPlaylistDTO> subsonicSortPlaylists(
  List<SubsonicPlaylistDTO> playlists,
  ItemSort sort,
  SortDirection direction, {
  Random? random,
}) {
  final compare = subsonicPlaylistComparator(sort);
  return _ordered(playlists, compare, direction, random: random);
}

List<SubsonicChildDTO> subsonicSortSongs(
  List<SubsonicChildDTO> songs,
  ItemSort sort,
  SortDirection direction, {
  Random? random,
}) {
  final compare = subsonicSongComparator(sort);
  if (compare == null && sort != ItemSort.random) return songs;
  return _ordered(songs, compare, direction, random: random);
}

List<SubsonicChildDTO> subsonicAlbumOrder(List<SubsonicChildDTO> songs) =>
    [...songs]..sort((a, b) {
      final byDisc = (a.discNumber ?? 0).compareTo(b.discNumber ?? 0);
      return byDisc != 0 ? byDisc : (a.track ?? 0).compareTo(b.track ?? 0);
    });

List<SubsonicChildDTO> subsonicFilterSongs(
  List<SubsonicChildDTO> songs,
  Set<ItemFilterFlag> filters,
) {
  if (filters.contains(ItemFilterFlag.played)) {
    return [
      for (final song in songs)
        if (song.playCount > 0) song,
    ];
  }
  if (filters.contains(ItemFilterFlag.unplayed)) {
    return [
      for (final song in songs)
        if (song.playCount == 0) song,
    ];
  }
  return songs;
}

Comparator<SubsonicAlbumDTO>? subsonicAlbumComparator(ItemSort sort) =>
    switch (sort) {
      ItemSort.random => null,
      ItemSort.dateCreated || ItemSort.dateLastContentAdded =>
        (a, b) => _compareNullable(a.created, b.created),
      ItemSort.releaseDate => (a, b) => _compareNullable(a.year, b.year),
      ItemSort.albumArtist => (a, b) => subsonicCompareNames(
        a.displayArtist ?? a.artist,
        b.displayArtist ?? b.artist,
      ),
      ItemSort.playCount => (a, b) => a.playCount.compareTo(b.playCount),
      ItemSort.datePlayed => (a, b) => _compareNullable(a.played, b.played),
      ItemSort.name || ItemSort.albumOrder => (a, b) => subsonicCompareNames(
        a.sortName ?? a.name,
        b.sortName ?? b.name,
      ),
    };

Comparator<SubsonicArtistDTO>? subsonicArtistComparator(ItemSort sort) =>
    switch (sort) {
      ItemSort.random => null,
      _ => (a, b) => subsonicCompareNames(
        a.sortName ?? a.name,
        b.sortName ?? b.name,
      ),
    };

Comparator<SubsonicGenreDTO>? subsonicGenreComparator(ItemSort sort) =>
    switch (sort) {
      ItemSort.random => null,
      ItemSort.playCount => (a, b) => a.songCount.compareTo(b.songCount),
      _ => (a, b) => subsonicCompareNames(a.value, b.value),
    };

Comparator<SubsonicPlaylistDTO>? subsonicPlaylistComparator(ItemSort sort) =>
    switch (sort) {
      ItemSort.random => null,
      ItemSort.dateLastContentAdded => (a, b) => _compareNullable(
        a.changed,
        b.changed,
      ),
      ItemSort.dateCreated => (a, b) => _compareNullable(a.created, b.created),
      _ => (a, b) => subsonicCompareNames(a.name, b.name),
    };

Comparator<SubsonicChildDTO>? subsonicSongComparator(ItemSort sort) =>
    switch (sort) {
      ItemSort.random => null,
      ItemSort.name => (a, b) => subsonicCompareNames(
        a.sortName ?? a.title,
        b.sortName ?? b.title,
      ),
      ItemSort.albumArtist => (a, b) => subsonicCompareNames(
        a.displayAlbumArtist ?? a.artist,
        b.displayAlbumArtist ?? b.artist,
      ),
      ItemSort.dateCreated => (a, b) => _compareNullable(a.created, b.created),
      ItemSort.playCount => (a, b) => a.playCount.compareTo(b.playCount),
      ItemSort.datePlayed => (a, b) => _compareNullable(a.played, b.played),
      ItemSort.releaseDate => (a, b) => _compareNullable(a.year, b.year),
      ItemSort.dateLastContentAdded || ItemSort.albumOrder => null,
    };
