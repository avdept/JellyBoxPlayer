import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

typedef MoreFromArtistKey = ({String artistId, String albumId});

const moreFromArtistLimit = 50;

final AutoDisposeFutureProviderFamily<List<LibraryItem>, MoreFromArtistKey>
moreFromArtistProvider = FutureProvider.autoDispose
    .family<List<LibraryItem>, MoreFromArtistKey>((ref, key) async {
      if (ref.watch(isOfflineProvider)) return const [];
      if (ref.watch(currentUserProvider) == null) return const [];

      final page = await ref
          .watch(mediaServerClientProvider)
          .getAlbums(
            LibraryQuery(
              artistIds: [key.artistId],
              sort: ItemSort.releaseDate,
              direction: SortDirection.descending,
              limit: moreFromArtistLimit,
            ),
          );
      return page.items.where((album) => album.id != key.albumId).toList();
    });
