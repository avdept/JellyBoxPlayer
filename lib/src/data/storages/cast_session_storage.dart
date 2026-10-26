import 'package:shared_preferences/shared_preferences.dart';

class CastSession {
  const CastSession({
    required this.udn,
    required this.location,
    required this.name,
  });

  final String udn;
  final Uri location;
  final String name;
}

class CastSessionStorage {
  static const _udnKey = 'cast_udn';
  static const _locationKey = 'cast_location';
  static const _nameKey = 'cast_name';

  static const List<String> _keys = [_udnKey, _locationKey, _nameKey];

  String _scoped(String key, String serverId) => '$key.$serverId';

  Future<void> save({
    required String serverId,
    required CastSession session,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_scoped(_udnKey, serverId), session.udn),
        prefs.setString(_scoped(_locationKey, serverId), '${session.location}'),
        prefs.setString(_scoped(_nameKey, serverId), session.name),
      ]);
    } on Object {
      // ignore
    }
  }

  Future<CastSession?> load(String serverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final udn = prefs.getString(_scoped(_udnKey, serverId));
      final location = Uri.tryParse(
        prefs.getString(_scoped(_locationKey, serverId)) ?? '',
      );
      final name = prefs.getString(_scoped(_nameKey, serverId));
      if (udn == null || name == null) return null;
      if (location == null || !location.hasScheme) return null;
      return CastSession(udn: udn, location: location, name: name);
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
}
