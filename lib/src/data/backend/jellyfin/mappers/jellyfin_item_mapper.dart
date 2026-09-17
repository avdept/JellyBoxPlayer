import 'package:jplayer/src/data/backend/mappers/item_dto_mapper.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

const jellyfinExternalIdKeys = <String, String>{
  'MusicBrainzAlbum': ExternalIdProvider.musicBrainzAlbum,
  'MusicBrainzReleaseGroup': ExternalIdProvider.musicBrainzReleaseGroup,
  'MusicBrainzArtist': ExternalIdProvider.musicBrainzArtist,
  'MusicBrainzAlbumArtist': ExternalIdProvider.musicBrainzAlbumArtist,
  'MusicBrainzTrack': ExternalIdProvider.musicBrainzTrack,
  'MusicBrainzRecording': ExternalIdProvider.musicBrainzRecording,
  'AudioDbAlbum': ExternalIdProvider.audioDbAlbum,
  'AudioDbArtist': ExternalIdProvider.audioDbArtist,
};

extension JellyfinItemMapping on ItemDTO {
  LibraryItem toJellyfinLibraryItem() {
    final item = toLibraryItem();
    return item.copyWith(
      externalIds: normalizeExternalIds(
        item.externalIds,
        jellyfinExternalIdKeys,
      ),
    );
  }
}

extension JellyfinItemsWrapperMapping on ItemsWrapper {
  LibraryPage toJellyfinLibraryPage() => LibraryPage(
    items: [for (final item in items) item.toJellyfinLibraryItem()],
    totalRecordCount: totalRecordCount,
  );
}
