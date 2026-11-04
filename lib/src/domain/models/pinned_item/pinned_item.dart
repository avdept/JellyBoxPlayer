import 'package:jplayer/src/domain/models/library_item/item_kind.dart';

typedef PinnedItem = ({
  String itemId,
  ItemKind kind,
  String name,
  Uri? imageUrl,
  DateTime pinnedAt,
});

const pinnableKinds = {
  ItemKind.song,
  ItemKind.album,
  ItemKind.artist,
  ItemKind.playlist,
};
