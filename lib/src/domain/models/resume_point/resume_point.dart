import 'package:jplayer/src/domain/models/ephemeral_playlist/ephemeral_playlist_id.dart';
import 'package:jplayer/src/domain/models/library_item/item_kind.dart';
import 'package:jplayer/src/domain/models/library_item/library_item.dart';

typedef ResumePoint = ({
  LibraryItem item,
  String songId,
  String songName,
  int songIndex,
  int songCount,
  Duration position,
  DateTime updatedAt,
});

const Set<ItemKind> resumableKinds = {
  ItemKind.album,
  ItemKind.artist,
  ItemKind.playlist,
};

bool canResume(LibraryItem set) =>
    resumableKinds.contains(set.kind) && !EphemeralPlaylistId.isGenerated(set.id);

const resumePointMaxAge = Duration(days: 60);

const resumePointMinPosition = Duration(seconds: 30);

bool isResumable(ResumePoint point) =>
    point.songIndex > 0 || point.position >= resumePointMinPosition;
