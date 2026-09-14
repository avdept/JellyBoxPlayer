import 'package:flutter/foundation.dart' show immutable;

@immutable
class AutoMediaId {
  const AutoMediaId(this.type, {this.id, this.start = 0, this.context});

  static const root = 'root';
  static const recent = 'recent';
  static const home = 'home';
  static const library = 'library';
  static const downloads = 'downloads';
  static const signIn = 'signin';
  static const resume = 'resume';
  static const albums = 'albums';
  static const artists = 'artists';
  static const playlists = 'playlists';
  static const songs = 'songs';
  static const artist = 'artist';
  static const artistAll = 'artist-all';
  static const album = 'album';
  static const download = 'download';
  static const playlist = 'playlist';
  static const mix = 'mix';
  static const song = 'song';

  static const Set<String> _plain = {
    root,
    recent,
    home,
    library,
    downloads,
    signIn,
    resume,
    albums,
    artists,
    playlists,
    songs,
  };
  static const Set<String> _withId = {
    artist,
    album,
    download,
    playlist,
    mix,
    song,
  };

  final String type;
  final String? id;
  final int start;
  final String? context;

  static AutoMediaId? parse(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || raw.isEmpty) return null;
    final segments = uri.pathSegments;
    final start = int.tryParse(uri.queryParameters['start'] ?? '') ?? 0;
    final context = uri.queryParameters['ctx'];
    if (start < 0) return null;

    switch (segments.length) {
      case 1:
        final type = segments.single;
        if (!_plain.contains(type)) return null;
        return AutoMediaId(type, start: start, context: context);
      case 2:
        final [type, id] = segments;
        if (!_withId.contains(type) || id.isEmpty) return null;
        return AutoMediaId(type, id: id, start: start, context: context);
      case 3:
        final [type, id, suffix] = segments;
        if (type != artist || id.isEmpty || suffix != 'all') return null;
        return AutoMediaId(artistAll, id: id);
      default:
        return null;
    }
  }

  String encode() {
    final path = switch (type) {
      artistAll => '$artist/${Uri.encodeComponent(id!)}/all',
      _ when id != null => '$type/${Uri.encodeComponent(id!)}',
      _ => type,
    };
    final query = <String, String>{
      if (start > 0) 'start': '$start',
      'ctx': ?context,
    };
    if (query.isEmpty) return path;
    final encoded = query.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$path?$encoded';
  }

  AutoMediaId withStart(int value) =>
      AutoMediaId(type, id: id, start: value, context: context);

  @override
  String toString() => encode();

  @override
  bool operator ==(Object other) =>
      other is AutoMediaId &&
      other.type == type &&
      other.id == id &&
      other.start == start &&
      other.context == context;

  @override
  int get hashCode => Object.hash(type, id, start, context);
}
