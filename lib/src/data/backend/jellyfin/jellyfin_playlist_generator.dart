import 'dart:math';

import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/playlist_generation.dart';
import 'package:jplayer/src/domain/models/models.dart';

const jellyfinGenreMixIdPrefix = 'jellybox:genre-mix:';
const jellyfinGenreDiscoveryIdPrefix = 'jellybox:genre-discovery:';

const _playedSongsScanLimit = 200;
const _genreCandidateCount = 5;
const _discoveryCandidateCount = 8;
const _maxMixPlaylists = 3;
const _maxDiscoveryPlaylists = 2;

String jellyfinGenreMixId(List<String> genreIds) =>
    '$jellyfinGenreMixIdPrefix${genreIds.join(',')}';

String jellyfinGenreDiscoveryId(List<String> genreIds) =>
    '$jellyfinGenreDiscoveryIdPrefix${genreIds.join(',')}';

bool isJellyfinDiscoveryPlaylistId(String id) =>
    id.startsWith(jellyfinGenreDiscoveryIdPrefix);

bool isJellyfinGeneratedPlaylistId(String id) =>
    id.startsWith(jellyfinGenreMixIdPrefix) ||
    isJellyfinDiscoveryPlaylistId(id);

List<String> jellyfinGenreIdsOf(String playlistId) {
  final prefix = isJellyfinDiscoveryPlaylistId(playlistId)
      ? jellyfinGenreDiscoveryIdPrefix
      : jellyfinGenreMixIdPrefix;
  return playlistId.substring(prefix.length).split(',');
}

Future<List<GeneratedPlaylist>> generateJellyfinTodaysPlaylists(
  MediaServerClient client, {
  required String userId,
  String? libraryId,
  bool includeDiscovery = false,
  Random? random,
}) async {
  final rng = random ?? Random();

  final played = await client.getAllSongs(
    userId: userId,
    libraryId: libraryId,
    sortBy: 'PlayCount',
    sortOrder: 'Descending',
    filters: const ['IsPlayed'],
    limit: '$_playedSongsScanLimit',
    fields: const ['Genres'],
  );

  final ranking = _rankPlayedGenres(played.items);
  if (ranking.ranked.isEmpty && !includeDiscovery) return const [];

  final allGenres = await client.getGenres(
    userId: userId,
    libraryId: libraryId,
    limit: '500',
  );

  final idsByKey = <String, List<String>>{};
  final nameByKey = <String, String>{};
  for (final genre in allGenres.items) {
    final key = genreKey(genre.name);
    if (key.isEmpty) continue;
    idsByKey.putIfAbsent(key, () => []).add(genre.id);
    nameByKey.putIfAbsent(key, () => genre.name);
  }

  final playlists = await _mixPlaylists(
    client,
    userId: userId,
    libraryId: libraryId,
    ranking: ranking,
    idsByKey: idsByKey,
  );

  if (!includeDiscovery) return playlists;

  return [
    ...playlists,
    ...await _discoveryPlaylists(
      client,
      userId: userId,
      libraryId: libraryId,
      idsByKey: idsByKey,
      nameByKey: nameByKey,
      playedKeys: ranking.playsPerKey.keys.toSet(),
      random: rng,
    ),
  ];
}

typedef _GenreRanking = ({
  List<String> ranked,
  Map<String, int> playsPerKey,
  Map<String, Map<String, int>> playsPerVariant,
});

_GenreRanking _rankPlayedGenres(List<LibraryItem> played) {
  final playsPerKey = <String, int>{};
  final playsPerVariant = <String, Map<String, int>>{};

  for (final song in played) {
    final plays = song.userData.playCount;
    if (plays == 0) continue;
    for (final genre in song.genres) {
      final key = genreKey(genre);
      if (key.isEmpty) continue;
      playsPerKey.update(key, (total) => total + plays, ifAbsent: () => plays);
      playsPerVariant
          .putIfAbsent(key, () => <String, int>{})
          .update(genre, (total) => total + plays, ifAbsent: () => plays);
    }
  }

  final ranked = playsPerKey.keys.toList()
    ..sort((a, b) => playsPerKey[b]!.compareTo(playsPerKey[a]!));

  return (
    ranked: ranked,
    playsPerKey: playsPerKey,
    playsPerVariant: playsPerVariant,
  );
}

Future<List<GeneratedPlaylist>> _mixPlaylists(
  MediaServerClient client, {
  required String userId,
  required String? libraryId,
  required _GenreRanking ranking,
  required Map<String, List<String>> idsByKey,
}) async {
  final candidates = <({String label, List<String> ids})>[];
  for (final key in ranking.ranked) {
    final ids = idsByKey[key];
    if (ids == null || ids.isEmpty) continue;
    final variants = ranking.playsPerVariant[key]!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    candidates.add((label: variants.first.key, ids: ids));
    if (candidates.length == _genreCandidateCount) break;
  }
  if (candidates.isEmpty) return const [];

  final probes = await Future.wait([
    for (final candidate in candidates)
      client.getSongsOfSet(
        userId: userId,
        libraryId: libraryId,
        genreIds: candidate.ids,
        sortBy: 'Random',
        limit: '$genreProbeLimit',
        fields: const [],
      ),
  ]);

  final playlists = <GeneratedPlaylist>[];
  for (var i = 0; i < candidates.length; i++) {
    if (achievablePlaylistLength(probes[i].items) <
        generatedPlaylistSongLimit) {
      continue;
    }
    playlists.add(
      GeneratedPlaylist(
        item: LibraryItem(
          id: jellyfinGenreMixId(candidates[i].ids),
          name: '${candidates[i].label} mix',
          kind: ItemKind.playlist,
        ),
        coverSongs: pickCoverSongs(probes[i].items),
      ),
    );
    if (playlists.length == _maxMixPlaylists) break;
  }

  return playlists;
}

Future<List<GeneratedPlaylist>> _discoveryPlaylists(
  MediaServerClient client, {
  required String userId,
  required String? libraryId,
  required Map<String, List<String>> idsByKey,
  required Map<String, String> nameByKey,
  required Set<String> playedKeys,
  required Random random,
}) async {
  final pool = idsByKey.keys.where((key) => !playedKeys.contains(key)).toList()
    ..shuffle(random);
  final candidates = pool.take(_discoveryCandidateCount).toList();
  if (candidates.isEmpty) return const [];

  final probes = await Future.wait([
    for (final key in candidates)
      client.getSongsOfSet(
        userId: userId,
        libraryId: libraryId,
        genreIds: idsByKey[key]!,
        filters: const ['IsUnplayed'],
        sortBy: 'Random',
        limit: '$genreProbeLimit',
        fields: const [],
      ),
  ]);

  final playlists = <GeneratedPlaylist>[];
  for (var i = 0; i < candidates.length; i++) {
    if (achievablePlaylistLength(probes[i].items) <
        generatedPlaylistSongLimit) {
      continue;
    }
    playlists.add(
      GeneratedPlaylist(
        item: LibraryItem(
          id: jellyfinGenreDiscoveryId(idsByKey[candidates[i]]!),
          name: 'Discover ${nameByKey[candidates[i]]}',
          kind: ItemKind.playlist,
        ),
        coverSongs: pickCoverSongs(probes[i].items),
      ),
    );
    if (playlists.length == _maxDiscoveryPlaylists) break;
  }

  return playlists;
}

Future<List<LibraryItem>> fetchJellyfinGeneratedPlaylistSongs(
  MediaServerClient client, {
  required String userId,
  required String playlistId,
  String? libraryId,
  Random? random,
}) async {
  if (!isJellyfinGeneratedPlaylistId(playlistId)) return const [];

  final genreIds = jellyfinGenreIdsOf(playlistId);
  final rng = random ?? Random();

  if (isJellyfinDiscoveryPlaylistId(playlistId)) {
    final unplayed = await client.getSongsOfSet(
      userId: userId,
      libraryId: libraryId,
      genreIds: genreIds,
      filters: const ['IsUnplayed'],
      sortBy: 'Random',
      limit: '$generatedPlaylistFetchLimit',
    );

    return blendSongs(
      familiar: const [],
      fresh: unplayed.items,
      random: rng,
    );
  }

  final batches = await Future.wait([
    client.getSongsOfSet(
      userId: userId,
      libraryId: libraryId,
      genreIds: genreIds,
      filters: const ['IsPlayed'],
      sortBy: 'PlayCount',
      sortOrder: 'Descending',
      limit: '$generatedPlaylistFetchLimit',
    ),
    client.getSongsOfSet(
      userId: userId,
      libraryId: libraryId,
      genreIds: genreIds,
      filters: const ['IsUnplayed'],
      sortBy: 'Random',
      limit: '$generatedPlaylistFetchLimit',
    ),
  ]);

  return blendSongs(
    familiar: [...batches[0].items]..shuffle(rng),
    fresh: batches[1].items,
    random: rng,
  );
}
