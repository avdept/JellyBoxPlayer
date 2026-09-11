import 'package:jplayer/src/core/enums/enums.dart';

enum ItemSort {
  name,
  albumArtist,
  dateCreated,
  datePlayed,
  playCount,
  dateLastContentAdded,
  albumOrder,
  random,
}

enum SortDirection { ascending, descending }

enum ItemFilterFlag { favorite, played, unplayed }

enum ItemField { audioSources, genres }

class LibraryQuery {
  const LibraryQuery({
    this.libraryId,
    this.sort = ItemSort.name,
    this.direction = SortDirection.ascending,
    this.filters = const {},
    this.fields = const {ItemField.audioSources},
    this.startIndex = 0,
    this.limit = 100,
    this.artistIds = const [],
    this.genreIds = const [],
    this.ids = const [],
    this.appearsOnArtistId,
    this.artistScope = ArtistScope.allArtists,
  });

  final String? libraryId;
  final ItemSort sort;
  final SortDirection direction;
  final Set<ItemFilterFlag> filters;
  final Set<ItemField> fields;
  final int startIndex;
  final int limit;
  final List<String> artistIds;
  final List<String> genreIds;
  final List<String> ids;
  final String? appearsOnArtistId;
  final ArtistScope artistScope;

  LibraryQuery copyWith({
    String? libraryId,
    ItemSort? sort,
    SortDirection? direction,
    Set<ItemFilterFlag>? filters,
    Set<ItemField>? fields,
    int? startIndex,
    int? limit,
    List<String>? artistIds,
    List<String>? genreIds,
    List<String>? ids,
    String? appearsOnArtistId,
    ArtistScope? artistScope,
  }) => LibraryQuery(
    libraryId: libraryId ?? this.libraryId,
    sort: sort ?? this.sort,
    direction: direction ?? this.direction,
    filters: filters ?? this.filters,
    fields: fields ?? this.fields,
    startIndex: startIndex ?? this.startIndex,
    limit: limit ?? this.limit,
    artistIds: artistIds ?? this.artistIds,
    genreIds: genreIds ?? this.genreIds,
    ids: ids ?? this.ids,
    appearsOnArtistId: appearsOnArtistId ?? this.appearsOnArtistId,
    artistScope: artistScope ?? this.artistScope,
  );

  @override
  String toString() =>
      'LibraryQuery(libraryId: $libraryId, sort: $sort, '
      'direction: $direction, filters: $filters, fields: $fields, '
      'startIndex: $startIndex, limit: $limit, artistIds: $artistIds, '
      'genreIds: $genreIds, ids: $ids, appearsOnArtistId: $appearsOnArtistId, '
      'artistScope: $artistScope)';
}

SortDirection sortDirectionOf({required bool descending}) =>
    descending ? SortDirection.descending : SortDirection.ascending;

extension EntityFilterSort on EntityFilter {
  ItemSort get itemSort => switch (this) {
    EntityFilter.sortName => ItemSort.name,
    EntityFilter.albumArtist => ItemSort.albumArtist,
    EntityFilter.dateCreated => ItemSort.dateCreated,
    EntityFilter.random => ItemSort.random,
  };
}

class SearchQuery {
  const SearchQuery({
    required this.term,
    this.libraryId,
    this.startIndex = 0,
    this.limit = 100,
    this.direction = SortDirection.descending,
    this.artistScope = ArtistScope.allArtists,
  });

  final String term;
  final String? libraryId;
  final int startIndex;
  final int limit;
  final SortDirection direction;
  final ArtistScope artistScope;

  @override
  String toString() =>
      'SearchQuery(term: $term, libraryId: $libraryId, '
      'startIndex: $startIndex, limit: $limit, direction: $direction, '
      'artistScope: $artistScope)';
}
