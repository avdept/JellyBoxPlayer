import 'package:jplayer/src/core/enums/entities.dart';

enum ItemList {
  albums(
    defaultSortField: EntityFilter.dateCreated,
    defaultSortDescending: true,
  ),
  artists(
    defaultSortField: EntityFilter.sortName,
    defaultSortDescending: false,
  ),
  genres(
    defaultSortField: EntityFilter.sortName,
    defaultSortDescending: false,
  ),
  playlists(
    defaultSortField: EntityFilter.sortName,
    defaultSortDescending: true,
  ),
  songs(
    defaultSortField: EntityFilter.sortName,
    defaultSortDescending: true,
  );

  const ItemList({
    required this.defaultSortField,
    required this.defaultSortDescending,
  });

  final EntityFilter defaultSortField;

  final bool defaultSortDescending;

  List<EntityFilter> sortOptions({bool albumRatingSort = false}) =>
      switch (this) {
        ItemList.albums => [
          EntityFilter.sortName,
          EntityFilter.albumArtist,
          EntityFilter.dateCreated,
          if (albumRatingSort) EntityFilter.rating,
          EntityFilter.random,
        ],
        ItemList.artists => const [
          EntityFilter.sortName,
          EntityFilter.dateCreated,
        ],
        ItemList.genres => const [EntityFilter.sortName],
        ItemList.playlists => const [
          EntityFilter.dateLastContentAdded,
          EntityFilter.sortName,
          EntityFilter.dateCreated,
        ],
        ItemList.songs => const [
          EntityFilter.sortName,
          EntityFilter.dateCreated,
          EntityFilter.albumArtist,
          EntityFilter.random,
        ],
      };
}
