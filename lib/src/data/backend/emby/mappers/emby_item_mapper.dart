import 'package:jplayer/src/data/backend/mappers/item_dto_mapper.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

extension EmbyMediaStreamMapping on MediaStreamDTO {
  bool get isLyricStream => type == 'Subtitle' && codec?.toLowerCase() == 'lrc';
}

extension EmbyMediaSourceMapping on MediaSourceDTO {
  MediaStreamDTO? get lyricStream =>
      mediaStreams.where((stream) => stream.isLyricStream).firstOrNull;
}

extension EmbyItemMapping on ItemDTO {
  bool get hasLyricStream =>
      mediaSources.any((source) => source.lyricStream != null);

  LibraryItem toEmbyLibraryItem() {
    final item = toLibraryItem();
    return item.copyWith(
      hasLyrics: hasLyricStream,
      images: _embyImages(item.images),
      userData: _embyUserData(item.userData),
    );
  }

  PlaybackUserData _embyUserData(PlaybackUserData mapped) =>
      mapped.played && mapped.playCount == 0
      ? mapped.copyWith(playCount: 1)
      : mapped;

  ImageRefs _embyImages(ImageRefs mapped) {
    if (mapped.primary != null || primaryImageTag == null) return mapped;
    return mapped.copyWith(
      primary: primaryImageTag,
      primaryItemId: primaryImageItemId,
    );
  }
}

extension EmbyItemsWrapperMapping on ItemsWrapper {
  LibraryPage toEmbyLibraryPage() => LibraryPage(
    items: [for (final item in items) item.toEmbyLibraryItem()],
    totalRecordCount: totalRecordCount,
  );
}
