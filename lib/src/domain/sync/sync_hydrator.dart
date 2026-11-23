import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/storages/generated_playlist_database.dart';
import 'package:jplayer/src/data/storages/instant_mix_database.dart';
import 'package:jplayer/src/data/storages/pins_database.dart';
import 'package:jplayer/src/data/storages/resume_point_database.dart';
import 'package:jplayer/src/domain/models/models.dart';

class SyncHydrator {
  SyncHydrator({
    required MediaServerClient client,
    required ResumePointDatabase resumePoints,
    required PinsDatabase pins,
    required GeneratedPlaylistDatabase generated,
    required InstantMixDatabase instantMixes,
    required String? userId,
  }) : _client = client,
       _resumePoints = resumePoints,
       _pins = pins,
       _generated = generated,
       _instantMixes = instantMixes,
       _userId = userId;

  static const batchSize = 100;

  final MediaServerClient _client;
  final ResumePointDatabase _resumePoints;
  final PinsDatabase _pins;
  final GeneratedPlaylistDatabase _generated;
  final InstantMixDatabase _instantMixes;
  final String? _userId;

  Future<bool> hydrateResumePoints() async {
    final stubs = await _resumePoints.stubs();
    if (stubs.isEmpty) return false;
    final songs = await _songs({
      for (final point in stubs)
        if (point.songName.isEmpty && point.songId.isNotEmpty) point.songId,
    });
    var filled = 0;
    for (final point in stubs) {
      final item = point.item.name.isEmpty
          ? await _set(point.item.id, point.item.kind)
          : null;
      final songName = point.songName.isEmpty
          ? songs[point.songId]?.name
          : null;
      if (item == null && songName == null) continue;
      await _resumePoints.fill(point.item.id, item: item, songName: songName);
      filled++;
    }
    _log('resume points', filled, stubs.length);
    return filled > 0;
  }

  Future<bool> hydratePins() async {
    final stubs = await _pins.stubs();
    var filled = 0;
    for (final pin in stubs) {
      final item = await _set(pin.itemId, pin.kind);
      if (item == null) continue;
      await _pins.fill(pin.itemId, name: item.name, imageUrl: _imageOf(item));
      filled++;
    }
    _log('pins', filled, stubs.length);
    return filled > 0;
  }

  Future<bool> hydrateGeneratedPlaylists() async {
    final userId = _userId;
    if (userId == null) return false;
    final ids = await _generated.stubSongIds(userId: userId);
    if (ids.isEmpty) return false;
    final songs = await _songs(ids);
    await _generated.fillSongs(songs, userId: userId);
    _log('generated playlist songs', songs.length, ids.length);
    return songs.isNotEmpty;
  }

  Future<bool> hydrateInstantMixes() async {
    final stubs = await _instantMixes.stubs();
    if (stubs.isEmpty) return false;
    final wanted = {
      for (final mix in stubs)
        for (final song in mix.songs)
          if (song.name.isEmpty) song.id,
    };
    final songs = await _songs(wanted);
    if (wanted.isNotEmpty && songs.isEmpty) {
      _log('instant mixes', 0, stubs.length);
      return false;
    }
    var filled = 0;
    for (final mix in stubs) {
      final seed = mix.seed.name.isEmpty
          ? await _set(mix.seed.id, mix.seed.kind)
          : mix.seed;
      if (seed == null) continue;
      final resolved = [
        for (final song in mix.songs)
          if (song.name.isNotEmpty) song else ?songs[song.id],
      ];
      if (resolved.isEmpty) continue;
      await _instantMixes.fill(
        InstantMix(
          item: mix.item,
          seed: seed,
          songs: resolved,
          libraryId: mix.libraryId,
        ),
      );
      filled++;
    }
    _log('instant mixes', filled, stubs.length);
    return filled > 0;
  }

  Future<LibraryItem?> _set(String id, ItemKind kind) async {
    if (EphemeralPlaylistId.isEphemeral(id)) return null;
    try {
      return await _client.getItem(id, kind: kind);
    } on Object catch (error) {
      debugPrint('[sync] could not load ${kind.name} $id: $error');
      return null;
    }
  }

  Future<Map<String, LibraryItem>> _songs(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    final list = ids.toList();
    final batches = await Future.wait([
      for (var start = 0; start < list.length; start += batchSize)
        _batch(list.sublist(start, min(start + batchSize, list.length))),
    ]);
    return {
      for (final batch in batches)
        for (final song in batch) song.id: song,
    };
  }

  Future<List<LibraryItem>> _batch(List<String> ids) async {
    try {
      return await _client.getItemsByIds(ids);
    } on Object catch (error) {
      debugPrint('[sync] could not load ${ids.length} songs: $error');
      return const [];
    }
  }

  static void _log(String what, int filled, int stubs) {
    if (stubs == 0) return;
    debugPrint('[sync] filled $filled of $stubs synced $what from the server');
  }

  Uri? _imageOf(LibraryItem item) {
    if (!item.images.hasCover) return null;
    try {
      return _client.imageUri(item);
    } on Object {
      return null;
    }
  }
}
