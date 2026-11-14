import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/domain/models/models.dart';

String mediaBrowserSort(ItemSort sort, {ItemKind target = ItemKind.album}) =>
    switch (sort) {
      ItemSort.name => 'SortName',
      ItemSort.albumArtist => 'AlbumArtist',
      ItemSort.dateCreated || ItemSort.dateLiked => 'DateCreated,SortName',
      ItemSort.releaseDate => 'PremiereDate,ProductionYear,SortName',
      ItemSort.datePlayed => 'DatePlayed',
      ItemSort.playCount => 'PlayCount',
      ItemSort.dateLastContentAdded => 'DateLastContentAdded',
      ItemSort.albumOrder => 'AlbumArtist,Album,ParentIndexNumber,IndexNumber',
      ItemSort.random => 'Random',
      ItemSort.rating => 'SortName',
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

const albumListFields = {ItemField.externalIds, ItemField.genres};

List<String> mediaBrowserFields(Set<ItemField> fields) => [
  for (final field in fields)
    switch (field) {
      ItemField.audioSources => 'MediaSources',
      ItemField.genres => 'Genres',
      ItemField.externalIds => 'ProviderIds',
    },
];

const mediaBrowserIdBatchSize = 100;
const mediaBrowserIdBatchConcurrency = 2;

Future<List<T>> mediaBrowserFetchByIds<T>(
  List<String> ids,
  Future<T> Function(List<String> batch) fetch,
) async {
  final batches = [
    for (var start = 0; start < ids.length; start += mediaBrowserIdBatchSize)
      ids.skip(start).take(mediaBrowserIdBatchSize).toList(),
  ];
  final pages = <T>[];
  for (
    var start = 0;
    start < batches.length;
    start += mediaBrowserIdBatchConcurrency
  ) {
    final round = batches.skip(start).take(mediaBrowserIdBatchConcurrency);
    pages.addAll(await Future.wait([for (final batch in round) fetch(batch)]));
  }
  return pages;
}
