import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/domain/models/models.dart';

class ItemImageRef {
  const ItemImageRef({required this.id, required this.tag});

  final String id;
  final String tag;

  static ItemImageRef? resolve(LibraryItem item, ImageKind kind) {
    switch (kind) {
      case ImageKind.backdrop:
        final tag = item.images.backdrops.firstOrNull;
        return (tag == null) ? null : ItemImageRef(id: item.id, tag: tag);

      case ImageKind.album:
        return _albumRef(item) ?? _ownRef(item);

      case ImageKind.primary:
        return _ownRef(item) ?? _albumRef(item);
    }
  }

  static ItemImageRef? _ownRef(LibraryItem item) {
    final tag = item.images.primary;
    if (tag == null) return null;
    return ItemImageRef(id: item.images.primaryItemId ?? item.id, tag: tag);
  }

  static ItemImageRef? _albumRef(LibraryItem item) {
    final id = item.albumId;
    final tag = item.images.albumPrimary;
    if (id == null || tag == null) return null;
    return ItemImageRef(id: id, tag: tag);
  }
}
