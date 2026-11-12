import 'package:jplayer/src/core/listenbrainz/listenbrainz_client.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_popularity.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/domain/models/models.dart';

const mediaBrowserTopSongsScanLimit = 300;
const mediaBrowserTopSongsMinimumPlayed = 5;

Future<List<LibraryItem>> mediaBrowserTopSongs(
  MediaServerClient client,
  LibraryItem artist, {
  required ListenBrainzClient listenBrainz,
  required int limit,
}) async {
  final page = await client.getSongsOfSet(
    LibraryQuery(
      artistIds: [artist.id],
      sort: ItemSort.playCount,
      direction: SortDirection.descending,
      limit: mediaBrowserTopSongsScanLimit,
    ),
  );
  final songs = page.items;
  if (songs.isEmpty) return const [];

  final artistMbid = artist.externalIds[ExternalIdProvider.musicBrainzArtist];
  if (artistMbid != null) {
    try {
      final ranked = rankByListenBrainz(
        songs,
        await listenBrainz.topRecordingsForArtist(artistMbid),
      );
      if (ranked.isNotEmpty) return ranked.take(limit).toList();
    } on Object {
      return mostPlayedSongs(songs, limit: limit);
    }
  }
  return mostPlayedSongs(songs, limit: limit);
}

List<LibraryItem> mostPlayedSongs(
  List<LibraryItem> songs, {
  required int limit,
}) {
  final played = [
    for (final song in songs)
      if (song.userData.playCount > 0) song,
  ]..sort((a, b) => b.userData.playCount.compareTo(a.userData.playCount));
  if (played.length < mediaBrowserTopSongsMinimumPlayed) return const [];
  return played.take(limit).toList();
}
