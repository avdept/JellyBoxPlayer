import 'package:jplayer/src/domain/models/ephemeral_playlist/ephemeral_playlist_id.dart';
import 'package:jplayer/src/domain/models/library_item/item_kind.dart';
import 'package:jplayer/src/domain/models/library_item/library_item.dart';

bool isInstantMixId(String id) => EphemeralPlaylistId.isInstantMix(id);

bool isSoundMixSeed(LibraryItem seed) =>
    seed.id.startsWith(EphemeralPlaylistId.soundSeedPrefix);

LibraryItem soundMixSeed(String query) {
  final trimmed = query.trim();
  final name = trimmed.isEmpty
      ? trimmed
      : trimmed[0].toUpperCase() + trimmed.substring(1);
  return LibraryItem(
    id: EphemeralPlaylistId.soundSeed(trimmed),
    name: name,
    kind: ItemKind.playlist,
  );
}

LibraryItem instantMixItem(LibraryItem seed, {required DateTime createdAt}) =>
    LibraryItem(
      id: EphemeralPlaylistId.instantMix(seed.id, createdAt),
      name: isSoundMixSeed(seed) ? '${seed.name} Mix' : "${seed.name}'s mix",
      kind: ItemKind.playlist,
      images: seed.images,
    );

class InstantMix {
  const InstantMix({
    required this.item,
    required this.seed,
    required this.songs,
    this.libraryId,
  });

  InstantMix.create({
    required this.seed,
    required this.songs,
    required DateTime createdAt,
    this.libraryId,
  }) : item = instantMixItem(seed, createdAt: createdAt);

  final LibraryItem seed;
  final LibraryItem item;
  final List<LibraryItem> songs;
  final String? libraryId;

  InstantMix withSongs(List<LibraryItem> songs) =>
      InstantMix(item: item, seed: seed, songs: songs, libraryId: libraryId);
}
