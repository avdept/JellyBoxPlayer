import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScrobbleQueue {
  ScrobbleQueue(
    this.serviceId, {
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const capacity = 500;

  final String serviceId;
  final Future<SharedPreferences> Function() _preferences;
  final List<Listen> _items = [];
  Future<void>? _loading;
  Future<void> _writing = Future<void>.value();

  String get storageKey => storageKeyFor(serviceId);

  static String storageKeyFor(String serviceId) =>
      'scrobble_pending_$serviceId';

  Future<List<Listen>> pending() async {
    await _load();
    return List.unmodifiable(_items);
  }

  Future<void> add(Listen listen) async {
    await _load();
    _items.add(listen);
    if (_items.length > capacity) {
      _items.removeRange(0, _items.length - capacity);
    }
    await _persist();
  }

  Future<void> remove(Iterable<Listen> listens) async {
    await _load();
    final sent = listens.toSet();
    _items.removeWhere(sent.contains);
    await _persist();
  }

  Future<void> clear() async {
    await _load();
    _items.clear();
    await _persist();
  }

  Future<void> _load() => _loading ??= _read();

  Future<void> _read() async {
    try {
      final stored = (await _preferences()).getString(storageKey);
      if (stored == null) return;
      final restored = [
        for (final entry in jsonDecode(stored) as List<dynamic>)
          if (entry is Map) Listen.fromJson(entry.cast<String, Object?>()),
      ];
      _items.addAll(restored);
    } on Object catch (error) {
      debugPrint('[Scrobble] pending $serviceId listens unreadable: $error');
    }
  }

  Future<void> _persist() {
    final encoded = jsonEncode([for (final listen in _items) listen.toJson()]);
    return _writing = _writing.then((_) async {
      try {
        await (await _preferences()).setString(storageKey, encoded);
      } on Object catch (error) {
        debugPrint(
          '[Scrobble] saving pending $serviceId listens failed: $error',
        );
      }
    });
  }
}
