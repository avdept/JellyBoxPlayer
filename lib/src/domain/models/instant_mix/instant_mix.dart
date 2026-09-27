import 'package:jplayer/src/domain/models/library_item/item_kind.dart';
import 'package:jplayer/src/domain/models/library_item/library_item.dart';

const instantMixIdPrefix = 'instant-mix:';

bool isInstantMixId(String id) => id.startsWith(instantMixIdPrefix);

LibraryItem instantMixItem(LibraryItem seed) => LibraryItem(
  id: '$instantMixIdPrefix${seed.id}',
  name: "${seed.name}'s mix",
  kind: ItemKind.playlist,
  images: seed.images,
);

class InstantMix {
  InstantMix({required this.seed, required this.songs, this.libraryId})
    : item = instantMixItem(seed);

  final LibraryItem seed;
  final LibraryItem item;
  final List<LibraryItem> songs;
  final String? libraryId;

  InstantMix withSongs(List<LibraryItem> songs) =>
      InstantMix(seed: seed, songs: songs, libraryId: libraryId);
}
