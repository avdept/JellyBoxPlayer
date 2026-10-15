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

int jellyfinStars(double? rating) => ((rating ?? 0) / 2).round().clamp(0, 5);

double jellyfinRating(int stars) => stars.clamp(0, 5) * 2.0;

extension JellyfinItemMapping on ItemDTO {
  LibraryItem toJellyfinLibraryItem() {
    final item = toLibraryItem();
    return item.copyWith(
      userData: item.userData.copyWith(
        rating: jellyfinStars(userData.rating),
      ),
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
