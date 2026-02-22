import 'dart:convert';

import 'package:jplayer/src/data/dto/dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaybackSnapshot {
  const PlaybackSnapshot({
    required this.songs,
    required this.album,
    required this.songId,
    required this.positionMs,
  });

  final List<ItemDTO> songs;
  final ItemDTO album;
  final String songId;
  final int positionMs;
}

class PlaybackStorage {
  static const _songsKey = 'pb_songs';
  static const _albumKey = 'pb_album';
  static const _songIdKey = 'pb_song_id';
  static const _positionMsKey = 'pb_position_ms';

  Future<void> save({
    required List<ItemDTO> songs,
    required ItemDTO album,
    required String songId,
    required int positionMs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsEncoded = jsonEncode(songs.map((s) => s.toJson()).toList());
      final albumEncoded = jsonEncode(album.toJson());
      await Future.wait([
        prefs.setString(_songsKey, songsEncoded),
        prefs.setString(_albumKey, albumEncoded),
        prefs.setString(_songIdKey, songId),
        prefs.setInt(_positionMsKey, positionMs),
      ]);
    } on Object {
      // ignore
    }
  }

  Future<PlaybackSnapshot?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsJson = prefs.getString(_songsKey);
      final albumJson = prefs.getString(_albumKey);
      final songId = prefs.getString(_songIdKey);
      final positionMs = prefs.getInt(_positionMsKey) ?? 0;

      if (songsJson == null || albumJson == null || songId == null) return null;

      final songs = (jsonDecode(songsJson) as List)
          .map((e) => ItemDTO.fromJson(e as Map<String, dynamic>))
          .toList();
      final album = ItemDTO.fromJson(jsonDecode(albumJson) as Map<String, dynamic>);
      return PlaybackSnapshot(
        songs: songs,
        album: album,
        songId: songId,
        positionMs: positionMs,
      );
    } on Object {
      return null;
    }
  }
}
