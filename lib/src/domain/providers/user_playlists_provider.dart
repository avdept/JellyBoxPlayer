import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/on_repeat_provider.dart';

final userPlaylistsProvider = Provider<List<LibraryItem>>((ref) {
  final userId = ref.watch(currentUserProvider)?.userId;
  if (userId == null) return const [];
  return [for (final playlist in UserPlaylist.all) playlist.itemFor(userId)];
});

final AutoDisposeFutureProviderFamily<bool, EphemeralPlaylistKind>
userPlaylistAvailableProvider = FutureProvider.autoDispose.family((
  ref,
  kind,
) async {
  switch (kind) {
    case EphemeralPlaylistKind.likedSongs:
      final page = await ref.watch(favouriteSongsProvider.future);
      return page.items.isNotEmpty;
    case EphemeralPlaylistKind.onRepeat:
      return await ref.watch(onRepeatCardProvider.future) != null;
    default:
      return false;
  }
});

final AutoDisposeFutureProvider<List<LibraryItem>>
availableUserPlaylistsProvider = FutureProvider.autoDispose((ref) async {
  final userId = ref.watch(currentUserProvider)?.userId;
  if (userId == null) return const [];
  final items = <LibraryItem>[];
  for (final playlist in UserPlaylist.all) {
    bool available;
    try {
      available = await ref.watch(
        userPlaylistAvailableProvider(playlist.kind).future,
      );
    } on Object {
      available = false;
    }
    if (available) items.add(playlist.itemFor(userId));
  }
  return items;
});
