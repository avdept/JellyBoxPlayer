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
}
