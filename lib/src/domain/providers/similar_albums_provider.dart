import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

final AutoDisposeFutureProviderFamily<List<ItemDTO>, String>
similarAlbumsProvider = FutureProvider.autoDispose
    .family<List<ItemDTO>, String>((ref, albumId) async {
      if (ref.watch(isOfflineProvider)) return const [];
      final user = ref.watch(currentUserProvider);
      if (user == null) return const [];

      final response = await ref
          .watch(jellyfinApiProvider)
          .getSimilarAlbums(albumId: albumId, userId: user.userId);
      return response.data.items.where((album) => album.id != albumId).toList();
    });
