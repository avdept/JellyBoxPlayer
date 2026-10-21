import 'dart:convert';

import 'package:jplayer/src/domain/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaybackSnapshot {
  const PlaybackSnapshot({
    required this.songs,
    required this.album,
    required this.songId,
    required this.positionMs,
    this.sourceId,
  });

  final List<LibraryItem> songs;
  final LibraryItem album;
  final String songId;
  final int positionMs;
  final String? sourceId;
}

class PlaybackStorage {
  static const _songsKey = 'pb_songs';
  static const _albumKey = 'pb_album';
  static const _songIdKey = 'pb_song_id';
  static const _positionMsKey = 'pb_position_ms';
  static const _sourceIdKey = 'pb_source_id';

  static const List<String> _keys = [
    _songsKey,
    _albumKey,
    _songIdKey,
    _positionMsKey,
    _sourceIdKey,
  ];

  String _scoped(String key, String serverId) => '$key.$serverId';

  Future<void> save({
    required String serverId,
    required List<LibraryItem> songs,
    required LibraryItem album,
    required String songId,
    required int positionMs,
    String? sourceId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songsEncoded = jsonEncode(songs.map((s) => s.toJson()).toList());
      final albumEncoded = jsonEncode(album.toJson());
      await Future.wait([
        prefs.setString(_scoped(_songsKey, serverId), songsEncoded),
        prefs.setString(_scoped(_albumKey, serverId), albumEncoded),
        prefs.setString(_scoped(_songIdKey, serverId), songId),
        prefs.setInt(_scoped(_positionMsKey, serverId), positionMs),
        if (sourceId != null)
          prefs.setString(_scoped(_sourceIdKey, serverId), sourceId)
        else
          prefs.remove(_scoped(_sourceIdKey, serverId)),
        ..._removeLegacy(prefs),
      ]);
    } on Object {
      // ignore
    }
  }

  Future<PlaybackSnapshot?> load(String serverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _adoptLegacy(prefs, serverId);
      final songsJson = prefs.getString(_scoped(_songsKey, serverId));
      final albumJson = prefs.getString(_scoped(_albumKey, serverId));
      final songId = prefs.getString(_scoped(_songIdKey, serverId));
      final positionMs = prefs.getInt(_scoped(_positionMsKey, serverId)) ?? 0;

      if (songsJson == null || albumJson == null || songId == null) return null;

      final songs = (jsonDecode(songsJson) as List)
          .map((e) => LibraryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final album = LibraryItem.fromJson(
        jsonDecode(albumJson) as Map<String, dynamic>,
      );
      return PlaybackSnapshot(
        songs: songs,
        album: album,
        songId: songId,
        positionMs: positionMs,
        sourceId: prefs.getString(_scoped(_sourceIdKey, serverId)),
      );
    } on Object {
      return null;
    }
  }

  Future<void> clear(String serverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        for (final key in _keys) prefs.remove(_scoped(key, serverId)),
      ]);
    } on Object {
      return;
    }
  }

  Future<void> _adoptLegacy(SharedPreferences prefs, String serverId) async {
    if (!prefs.containsKey(_songsKey)) return;
    if (!prefs.containsKey(_scoped(_songsKey, serverId))) {
      final songs = prefs.getString(_songsKey);
      final album = prefs.getString(_albumKey);
      final songId = prefs.getString(_songIdKey);
      final sourceId = prefs.getString(_sourceIdKey);
      await Future.wait([
        if (songs != null) prefs.setString(_scoped(_songsKey, serverId), songs),
        if (album != null) prefs.setString(_scoped(_albumKey, serverId), album),
        if (songId != null)
          prefs.setString(_scoped(_songIdKey, serverId), songId),
        prefs.setInt(
          _scoped(_positionMsKey, serverId),
          prefs.getInt(_positionMsKey) ?? 0,
        ),
        if (sourceId != null)
          prefs.setString(_scoped(_sourceIdKey, serverId), sourceId),
      ]);
    }
    await Future.wait(_removeLegacy(prefs));
  }

  List<Future<bool>> _removeLegacy(SharedPreferences prefs) => [
    if (prefs.containsKey(_songsKey))
      for (final key in _keys) prefs.remove(key),
  ];
}
