import 'dart:ui' show Size;

import 'package:shared_preferences/shared_preferences.dart';

class WindowSizeStorage {
  const WindowSizeStorage(this._prefs);

  final SharedPreferences _prefs;

  Future<bool> saveWindowSize(Size size) async {
    return _prefs.setString(
      'window_size',
      [size.width, size.height].join('x'),
    );
  }

  Future<Size?> getWindowSize() async {
    final parts = _prefs.getString('window_size')?.split('x') ?? const [];
    if (parts.length != 2) return null;
    return Size(
      double.parse(parts.first),
      double.parse(parts.last),
    );
  }
}
