import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';

Future<LibraryItem> toggleFavourite(WidgetRef ref, LibraryItem item) async {
  final favorite = !item.userData.isFavorite;
  await ref
      .read(mediaServerClientProvider)
      .setFavorite(item.id, favorite: favorite);
  switch (item.kind) {
    case ItemKind.album:
      ref.invalidate(favouriteAlbumsProvider);
    case ItemKind.artist:
      ref.invalidate(favouriteArtistsProvider);
    case ItemKind.song:
      ref.invalidate(favouriteSongsProvider);
    case _:
      break;
  }
  return item.copyWith(
    userData: item.userData.copyWith(isFavorite: favorite),
  );
}
