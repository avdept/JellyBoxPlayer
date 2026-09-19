import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/domain/models/models.dart';

const mediaBrowserPlayedSongsScanLimit = 200;

Future<List<LibraryItem>> mediaBrowserRecentlyPlayedAlbums(
  MediaServerClient client, {
  required int limit,
  String? libraryId,
}) async {
  final played = await client.getAllSongs(
    LibraryQuery(
      libraryId: libraryId,
      sort: ItemSort.datePlayed,
      direction: SortDirection.descending,
      filters: const {ItemFilterFlag.played},
      limit: mediaBrowserPlayedSongsScanLimit,
    ),
  );

  final albumIds = <String>[];
  for (final song in played.items) {
    final albumId = song.albumId;
    if (albumId == null || albumIds.contains(albumId)) continue;
    albumIds.add(albumId);
    if (albumIds.length == limit) break;
  }

  return mediaBrowserAlbumsByIds(client, albumIds);
}

Future<List<LibraryItem>> mediaBrowserMostPlayedAlbums(
  MediaServerClient client, {
  required int limit,
  String? libraryId,
}) async {
  final played = await client.getAllSongs(
    LibraryQuery(
      libraryId: libraryId,
      sort: ItemSort.playCount,
      direction: SortDirection.descending,
      filters: const {ItemFilterFlag.played},
      limit: mediaBrowserPlayedSongsScanLimit,
    ),
  );

  final playsPerAlbum = <String, int>{};
  for (final song in played.items) {
    final albumId = song.albumId;
    if (albumId == null) continue;
    playsPerAlbum.update(
      albumId,
      (total) => total + song.userData.playCount,
      ifAbsent: () => song.userData.playCount,
    );
  }

  final albumIds = playsPerAlbum.keys.toList()
    ..sort((a, b) => playsPerAlbum[b]!.compareTo(playsPerAlbum[a]!));

  return mediaBrowserAlbumsByIds(client, albumIds.take(limit).toList());
}

Future<List<LibraryItem>> mediaBrowserAlbumsByIds(
  MediaServerClient client,
  List<String> albumIds,
) async {
  if (albumIds.isEmpty) return const [];
  final albums = await client.getAlbums(
    LibraryQuery(ids: albumIds, limit: albumIds.length),
  );
  final byId = {for (final album in albums.items) album.id: album};
  return [for (final id in albumIds) ?byId[id]];
}
