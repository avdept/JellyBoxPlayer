import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

final AutoDisposeFutureProviderFamily<List<LibraryItem>, String>
similarAlbumsProvider = FutureProvider.autoDispose
    .family<List<LibraryItem>, String>((ref, albumId) async {
      if (ref.watch(isOfflineProvider)) return const [];
      final user = ref.watch(currentUserProvider);
      if (user == null) return const [];

      final response = await ref
          .watch(mediaServerClientProvider)
          .getSimilarAlbums(albumId: albumId, userId: user.userId);
      return response.items.where((album) => album.id != albumId).toList();
    });
