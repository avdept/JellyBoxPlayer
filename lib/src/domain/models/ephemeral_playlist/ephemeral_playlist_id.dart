import 'package:optional_features/genre_playlists.dart';

enum EphemeralPlaylistKind {
  likedSongs,
  instantMix,
  soundMix,
  genreMix,
  genreDiscovery,
}

class EphemeralPlaylistId {
  const EphemeralPlaylistId._(this.kind, this.key, this.createdAt);

  final EphemeralPlaylistKind kind;
  final String key;
  final DateTime? createdAt;

  static const likedSongsPrefix = 'jellybox:liked-songs:';
  static const instantMixPrefix = 'instant-mix:';
  static const soundSeedPrefix = 'sound:';

  static final _stamp = RegExp(r':(\d+)$');

  static String likedSongs(String userId) => '$likedSongsPrefix$userId';

  static String instantMix(String seedId, DateTime at) =>
      '$instantMixPrefix$seedId:${at.millisecondsSinceEpoch}';

  static String soundSeed(String query) =>
      '$soundSeedPrefix${query.trim().toLowerCase()}';

  static EphemeralPlaylistId? parse(String id) {
    if (id.startsWith(likedSongsPrefix)) {
      final userId = id.substring(likedSongsPrefix.length);
      if (userId.isEmpty) return null;
      return EphemeralPlaylistId._(
        EphemeralPlaylistKind.likedSongs,
        userId,
        null,
      );
    }
    if (id.startsWith(instantMixPrefix)) {
      final (body, at) = _split(id.substring(instantMixPrefix.length));
      if (body.isEmpty) return null;
      if (body.startsWith(soundSeedPrefix)) {
        return EphemeralPlaylistId._(
          EphemeralPlaylistKind.soundMix,
          body.substring(soundSeedPrefix.length),
          at,
        );
      }
      return EphemeralPlaylistId._(EphemeralPlaylistKind.instantMix, body, at);
    }
    if (isGeneratedPlaylistId(id)) {
      final genres = genreIdsOf(id);
      if (genres.isEmpty) return null;
      return EphemeralPlaylistId._(
        isDiscoveryPlaylistId(id)
            ? EphemeralPlaylistKind.genreDiscovery
            : EphemeralPlaylistKind.genreMix,
        genres.join(','),
        generatedPlaylistCreatedAt(id),
      );
    }
    return null;
  }

  static (String, DateTime?) _split(String body) {
    final stamp = _stamp.firstMatch(body);
    if (stamp == null || stamp.start == 0) return (body, null);
    return (
      body.substring(0, stamp.start),
      DateTime.fromMillisecondsSinceEpoch(int.parse(stamp.group(1)!)),
    );
  }

  static bool isEphemeral(String id) => parse(id) != null;

  static bool isLikedSongs(String id) =>
      parse(id)?.kind == EphemeralPlaylistKind.likedSongs;

  static bool isInstantMix(String id) => switch (parse(id)?.kind) {
    EphemeralPlaylistKind.instantMix || EphemeralPlaylistKind.soundMix => true,
    _ => false,
  };

  static bool isGenerated(String id) => switch (parse(id)?.kind) {
    EphemeralPlaylistKind.genreMix ||
    EphemeralPlaylistKind.genreDiscovery => true,
    _ => false,
  };
}
