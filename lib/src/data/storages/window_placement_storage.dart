import 'dart:ui' show Offset, Size;

import 'package:shared_preferences/shared_preferences.dart';

class WindowPlacementStorage {
  const WindowPlacementStorage(this._prefs);

  static const _sizeKey = 'window_size';
  static const _positionKey = 'window_position';

  final SharedPreferences _prefs;

  Future<bool> saveWindowSize(Size size) async {
    return _prefs.setString(_sizeKey, [size.width, size.height].join('x'));
  }

  Future<Size?> getWindowSize() async {
    final pair = _readPair(_sizeKey);
    return pair == null ? null : Size(pair.$1, pair.$2);
  }

  Future<bool> saveWindowPosition(Offset position) async {
    return _prefs.setString(
      _positionKey,
      [position.dx, position.dy].join('x'),
    );
  }

  Future<Offset?> getWindowPosition() async {
    final pair = _readPair(_positionKey);
    return pair == null ? null : Offset(pair.$1, pair.$2);
  }

  (double, double)? _readPair(String key) {
    final parts = _prefs.getString(key)?.split('x') ?? const [];
    if (parts.length != 2) return null;
    final first = double.tryParse(parts.first);
    final second = double.tryParse(parts.last);
    if (first == null || second == null) return null;
    if (!first.isFinite || !second.isFinite) return null;
    return (first, second);
  }
}
