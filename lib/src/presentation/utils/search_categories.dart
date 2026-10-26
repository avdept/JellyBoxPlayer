import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/generated/l10n.dart';
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

String get soundSearchLabel => S.current.soundsLike;

String searchCategoryLabel(ItemList category) => switch (category) {
  ItemList.albums => S.current.albums,
  ItemList.artists => S.current.artists,
  ItemList.genres => S.current.genres,
  ItemList.playlists => S.current.playlists,
  ItemList.songs => S.current.songs,
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
