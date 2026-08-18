import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';

const searchCategories = [
  ItemList.albums,
  ItemList.artists,
  ItemList.playlists,
  ItemList.songs,
];

int searchSongsPreviewLimit({required bool isMobile}) => isMobile ? 8 : 20;

String searchCategoryLabel(ItemList category) => switch (category) {
  ItemList.albums => 'Albums',
  ItemList.artists => 'Artists',
  ItemList.genres => 'Genres',
  ItemList.playlists => 'Playlists',
  ItemList.songs => 'Songs',
};

void openSearchResult(
  BuildContext context,
  WidgetRef ref,
  ItemList category,
  LibraryItem item,
) {
  switch (category) {
    case ItemList.albums:
      ref.read(currentAlbumProvider.notifier).setAlbum(item);
      context.pushNamed(
        branchAwareName(context, Routes.album),
        extra: {'album': item},
      );
    case ItemList.artists:
      context.pushNamed(
        branchAwareName(context, Routes.artist),
        extra: {'artist': item},
      );
    case ItemList.playlists:
      ref.read(currentPlaylistProvider.notifier).setPlaylist(item);
      context.pushNamed(
        branchAwareName(context, Routes.playlist),
        extra: {'playlist': item},
      );
    case ItemList.genres:
      context.pushNamed(
        branchAwareName(context, Routes.genre),
        extra: {'genre': item},
      );
    case ItemList.songs:
      break;
  }
}

String favouriteMenuLabel(LibraryItem song) =>
    song.userData.isFavorite ? 'Remove from favourites' : 'Add to favourites';
