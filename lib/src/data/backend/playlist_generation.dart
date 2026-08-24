import 'dart:math';

import 'package:jplayer/src/domain/models/models.dart';

const generatedPlaylistSongLimit = 20;
const generatedPlaylistFetchLimit = 60;
const genreProbeLimit = 40;
const maxSongsPerAlbum = 2;
const coverSongCount = 4;

const _familiarRun = 1;
const _freshRun = 4;

final _nonAlphanumeric = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

String genreKey(String name) =>
    name.toLowerCase().replaceAll('&', 'and').replaceAll(_nonAlphanumeric, '');

int achievablePlaylistLength(List<LibraryItem> pool) {
  final perAlbum = <String, int>{};
  for (final song in pool) {
    perAlbum.update(
      song.albumId ?? song.id,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  var total = 0;
  for (final count in perAlbum.values) {
    total += count < maxSongsPerAlbum ? count : maxSongsPerAlbum;
  }
  return total;
}

List<LibraryItem> pickCoverSongs(List<LibraryItem> pool) {
  final picks = <LibraryItem>[];
  final seenAlbums = <String>{};
  for (final song in pool) {
    if (song.coverImageTag == null) {
      continue;
    }
    if (!seenAlbums.add(song.albumId ?? song.id)) continue;
    picks.add(song);
    if (picks.length == coverSongCount) break;
  }
  return picks;
}

List<LibraryItem> blendSongs({
  required List<LibraryItem> familiar,
  required List<LibraryItem> fresh,
  required Random random,
}) {
  final blended = <LibraryItem>[];
  final seen = <String>{};
  final perAlbum = <String, int>{};
  var familiarIndex = 0;
  var freshIndex = 0;

  bool accept(LibraryItem song) {
    if (!seen.add(song.id)) return false;
    final albumKey = song.albumId ?? song.id;
    final taken = perAlbum[albumKey] ?? 0;
    if (taken == maxSongsPerAlbum) return false;
    perAlbum[albumKey] = taken + 1;
    blended.add(song);
    return true;
  }

  int fill(List<LibraryItem> source, int from, int count) {
    var index = from;
    var added = 0;
    while (index < source.length && added < count) {
      if (blended.length == generatedPlaylistSongLimit) break;
      if (accept(source[index])) added++;
      index++;
    }
    return index;
  }

  while (blended.length < generatedPlaylistSongLimit &&
      (familiarIndex < familiar.length || freshIndex < fresh.length)) {
    final familiarBefore = familiarIndex;
    final freshBefore = freshIndex;
    familiarIndex = fill(familiar, familiarIndex, _familiarRun);
    freshIndex = fill(fresh, freshIndex, _freshRun);
    if (familiarIndex == familiarBefore && freshIndex == freshBefore) break;
  }

  return blended..shuffle(random);
}
