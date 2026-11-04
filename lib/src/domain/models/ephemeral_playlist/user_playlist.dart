import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/models/ephemeral_playlist/ephemeral_playlist_id.dart';
import 'package:jplayer/src/domain/models/models.dart';

class UserPlaylist {
  const UserPlaylist._({
    required this.kind,
    required this.name,
    required this.cover,
    required String Function(String userId) id,
    this.keepsLocalOrder = false,
  }) : _id = id;

  final EphemeralPlaylistKind kind;
  final String name;
  final String cover;
  final bool keepsLocalOrder;
  final String Function(String userId) _id;

  String idFor(String userId) => _id(userId);

  LibraryItem itemFor(String userId) =>
      LibraryItem(id: idFor(userId), name: name, kind: ItemKind.playlist);

  static const likedSongs = UserPlaylist._(
    kind: EphemeralPlaylistKind.likedSongs,
    name: 'Liked songs',
    cover: Images.likedSongs,
    id: EphemeralPlaylistId.likedSongs,
    keepsLocalOrder: true,
  );

  static const onRepeat = UserPlaylist._(
    kind: EphemeralPlaylistKind.onRepeat,
    name: 'On repeat',
    cover: Images.onRepeat,
    id: EphemeralPlaylistId.onRepeat,
  );

  static const all = [likedSongs, onRepeat];

  static UserPlaylist? of(String id) {
    final kind = EphemeralPlaylistId.parse(id)?.kind;
    if (kind == null) return null;
    for (final playlist in all) {
      if (playlist.kind == kind) return playlist;
    }
    return null;
  }
}
