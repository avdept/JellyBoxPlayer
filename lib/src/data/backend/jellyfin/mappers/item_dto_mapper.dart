import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';

extension ItemDTOMapping on ItemDTO {
  LibraryItem toLibraryItem() {
    return LibraryItem(
      id: id,
      name: name,
      kind: _kindFromType(type),
      indexNumber: indexNumber,
      duration: duration,
      path: path,
      collectionType: collectionType,
      playlistItemId: playlistItemId,
      overview: overview,
      productionYear: productionYear,
      albumId: albumId,
      albumName: albumName,
      albumArtist: albumArtist,
      albumArtists: albumArtists
          .map((artist) => ArtistRef(id: artist.id, name: artist.name))
          .toList(),
      images: ImageRefs(
        primary: imageTags['Primary'],
        albumPrimary: albumPrimaryImageTag,
        backdrops: backdropImageTags,
      ),
      hasLyrics: hasLyrics,
      userData: PlaybackUserData(
        position: Duration(
          milliseconds: (userData.playbackPositionTicks / 10000).round(),
        ),
        playCount: userData.playCount,
        isFavorite: userData.isFavorite,
        played: userData.played,
      ),
      audioSources: [
        for (final source in mediaSources) _toAudioSourceInfo(source),
      ],
    );
  }
}

AudioSourceInfo _toAudioSourceInfo(MediaSourceDTO source) {
  final audioStream = source.mediaStreams
      .where((stream) => stream.type == 'Audio')
      .firstOrNull;
  return AudioSourceInfo(
    container: source.container,
    codec: audioStream?.codec,
    bitRate: audioStream?.bitRate,
    sampleRate: audioStream?.sampleRate,
    bitDepth: audioStream?.bitDepth,
    channels: audioStream?.channels,
    channelLayout: audioStream?.channelLayout,
  );
}

extension ItemsWrapperMapping on ItemsWrapper {
  LibraryPage toLibraryPage() => LibraryPage(
    items: items.map((item) => item.toLibraryItem()).toList(),
    totalRecordCount: totalRecordCount,
  );
}

ItemKind _kindFromType(String type) {
  switch (type) {
    case 'Audio':
      return ItemKind.song;
    case 'MusicAlbum':
      return ItemKind.album;
    case 'Artist':
      return ItemKind.artist;
    case 'Playlist':
      return ItemKind.playlist;
    case 'MusicGenre':
      return ItemKind.genre;
    case 'CollectionFolder':
    case 'Library':
      return ItemKind.library;
    default:
      return ItemKind.unknown;
  }
}

extension LibraryItemToItemDTOMapping on LibraryItem {
  ItemDTO toItemDTO() => ItemDTO(
    id: id,
    name: name,
    type: _typeFromKind(kind),
    indexNumber: indexNumber,
    runTimeTicks: duration.inSeconds * 10000000,
    path: path,
    collectionType: collectionType,
    playlistItemId: playlistItemId,
    overview: overview,
    productionYear: productionYear,
    albumId: albumId,
    albumPrimaryImageTag: images.albumPrimary,
    albumName: albumName,
    albumArtist: albumArtist,
    albumArtists: albumArtists
        .map((artist) => ArtistDTO(id: artist.id, name: artist.name))
        .toList(),
    backdropImageTags: images.backdrops,
    imageTags: {if (images.primary != null) 'Primary': images.primary!},
    hasLyrics: hasLyrics,
    userData: UserData(
      playbackPositionTicks: userData.position.inMilliseconds * 10000,
      playCount: userData.playCount,
      isFavorite: userData.isFavorite,
      played: userData.played,
    ),
  );
}

String _typeFromKind(ItemKind kind) {
  switch (kind) {
    case ItemKind.song:
      return 'Audio';
    case ItemKind.album:
      return 'MusicAlbum';
    case ItemKind.artist:
      return 'Artist';
    case ItemKind.playlist:
      return 'Playlist';
    case ItemKind.genre:
      return 'MusicGenre';
    case ItemKind.library:
      return 'CollectionFolder';
    case ItemKind.unknown:
      return '';
  }
}
