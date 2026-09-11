import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/domain/models/models.dart';

String mediaBrowserSort(ItemSort sort, {ItemKind target = ItemKind.album}) =>
    switch (sort) {
      ItemSort.name => target == ItemKind.song ? 'Name' : 'SortName',
      ItemSort.albumArtist => 'AlbumArtist',
      ItemSort.dateCreated => 'DateCreated,SortName',
      ItemSort.datePlayed => 'DatePlayed',
      ItemSort.playCount => 'PlayCount',
      ItemSort.dateLastContentAdded => 'DateLastContentAdded',
      ItemSort.albumOrder => 'AlbumArtist,Album,ParentIndexNumber,IndexNumber',
      ItemSort.random => 'Random',
    };

String mediaBrowserSortOrder(SortDirection direction) => switch (direction) {
  SortDirection.ascending => 'Ascending',
  SortDirection.descending => 'Descending',
};

List<String> mediaBrowserFilters(Set<ItemFilterFlag> filters) => [
  for (final flag in filters)
    switch (flag) {
      ItemFilterFlag.favorite => 'IsFavorite',
      ItemFilterFlag.played => 'IsPlayed',
      ItemFilterFlag.unplayed => 'IsUnplayed',
    },
];

List<String> mediaBrowserFields(Set<ItemField> fields) => [
  for (final field in fields)
    switch (field) {
      ItemField.audioSources => 'MediaSources',
      ItemField.genres => 'Genres',
    },
];
