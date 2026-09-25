import 'dart:math';

import 'package:optional_features/genre_playlists.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/domain/models/models.dart';

export 'package:optional_features/genre_playlists.dart'
    show
        genreDiscoveryId,
        genreDiscoveryIdPrefix,
        genreIdsOf,
        genreMixId,
        genreMixIdPrefix,
        isDiscoveryPlaylistId,
        isGeneratedPlaylistId;

class MediaServerGenreSource implements GenrePlaylistSource<LibraryItem> {
  const MediaServerGenreSource(this.client, {this.libraryId});

  final MediaServerClient client;
  final String? libraryId;

  @override
  String idOf(LibraryItem song) => song.id;

  @override
  String? albumIdOf(LibraryItem song) => song.albumId;

  @override
  List<String> genresOf(LibraryItem song) => song.genres;

  @override
  int playCountOf(LibraryItem song) => song.userData.playCount;

  @override
  bool hasCoverOf(LibraryItem song) => song.images.hasCover;

  @override
  Future<List<LibraryItem>> mostPlayedSongs({required int limit}) async {
    final page = await client.getAllSongs(
      LibraryQuery(
        libraryId: libraryId,
        sort: ItemSort.playCount,
        direction: SortDirection.descending,
        filters: const {ItemFilterFlag.played},
        fields: const {ItemField.genres},
        limit: limit,
      ),
    );
    return page.items;
  }

  @override
  Future<List<GenreRef>> genres({required int limit}) async {
    final page = await client.getGenres(
      LibraryQuery(libraryId: libraryId, limit: limit),
    );
    return [
      for (final genre in page.items) GenreRef(id: genre.id, name: genre.name),
    ];
  }

  @override
  Future<List<LibraryItem>> genreSongs(
    List<String> genreIds, {
    required SongPool pool,
    required SongOrder order,
    required int limit,
    required bool forPlayback,
  }) async {
    final query = LibraryQuery(
      libraryId: libraryId,
      genreIds: genreIds,
      filters: switch (pool) {
        SongPool.any => const {},
        SongPool.played => const {ItemFilterFlag.played},
        SongPool.unplayed => const {ItemFilterFlag.unplayed},
      },
      sort: switch (order) {
        SongOrder.random => ItemSort.random,
        SongOrder.mostPlayed => ItemSort.playCount,
      },
      direction: order == SongOrder.mostPlayed
          ? SortDirection.descending
          : SortDirection.ascending,
      limit: limit,
    );
    final page = await client.getSongsOfSet(
      forPlayback ? query : query.copyWith(fields: const {}),
    );
    return page.items;
  }
}

GenrePlaylistGenerator<LibraryItem> _generator(
  MediaServerClient client, {
  required String? libraryId,
  required Random? random,
}) => GenrePlaylistGenerator(
  MediaServerGenreSource(client, libraryId: libraryId),
  random: random,
);

Future<List<GeneratedPlaylist>> generateGenrePlaylists(
  MediaServerClient client, {
  String? libraryId,
  bool includeDiscovery = false,
  Random? random,
}) async {
  final specs = await _generator(
    client,
    libraryId: libraryId,
    random: random,
  ).generate(includeDiscovery: includeDiscovery);
  return [
    for (final spec in specs)
      GeneratedPlaylist(
        item: LibraryItem(
          id: spec.id,
          name: spec.name,
          kind: ItemKind.playlist,
        ),
        coverSongs: spec.coverSongs,
      ),
  ];
}

Future<List<LibraryItem>> fetchGenrePlaylistSongs(
  MediaServerClient client, {
  required String playlistId,
  String? libraryId,
  Random? random,
}) => _generator(
  client,
  libraryId: libraryId,
  random: random,
).songsFor(playlistId);
