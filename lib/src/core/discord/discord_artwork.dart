import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/musicbrainz/cover_art_finder.dart';
import 'package:optional_features/catalog.dart';

class DiscordArtwork {
  DiscordArtwork({
    required Future<String?> Function(CoverArtQuery query) find,
    CatalogCacheStore? cache,
    DateTime Function()? now,
  }) : _find = find,
       _store = cache,
       _now = now ?? DateTime.now;

  static const sourceId = 'discord_artwork';
  static const foundLifetime = Duration(days: 30);
  static const missingLifetime = Duration(days: 3);
  static const retryDelay = Duration(minutes: 10);

  final Future<String?> Function(CoverArtQuery query) _find;
  final CatalogCacheStore? _store;
  final DateTime Function() _now;
  final _covers = <String, String?>{};
  final _pending = <String>{};
  final _retryAt = <String, DateTime>{};

  void Function()? onCoverFound;

  String? coverFor(CoverArtQuery query) {
    final key = query.key;
    if (key == null) return null;
    if (_covers.containsKey(key)) return _covers[key];
    if (_pending.contains(key)) return null;
    final retryAt = _retryAt[key];
    if (retryAt != null && _now().isBefore(retryAt)) return null;

    _pending.add(key);
    unawaited(_resolve(key, query));
    return null;
  }

  Future<void> _resolve(String key, CoverArtQuery query) async {
    try {
      final stored = await _read(key);
      final String? cover;
      if (stored != null) {
        cover = stored.url;
      } else {
        cover = await _find(query);
        await _write(key, cover);
      }
      _covers[key] = cover;
      _retryAt.remove(key);
      if (cover != null) onCoverFound?.call();
    } on Object catch (error) {
      debugPrint('[Discord] artwork lookup failed: $error');
      _retryAt[key] = _now().add(retryDelay);
    } finally {
      _pending.remove(key);
    }
  }

  Future<({String? url})?> _read(String key) async {
    try {
      final entry = await _store?.read(sourceId, key);
      if (entry == null || !entry.expires.isAfter(_now())) return null;
      final json = jsonDecode(entry.json) as Map<String, dynamic>;
      return (url: json['url'] as String?);
    } on Object {
      return null;
    }
  }

  Future<void> _write(String key, String? url) async {
    try {
      await _store?.write(
        sourceId,
        key,
        jsonEncode({'url': url}),
        expires: _now().add(url == null ? missingLifetime : foundLifetime),
      );
    } on Object {
      return;
    }
  }
}
