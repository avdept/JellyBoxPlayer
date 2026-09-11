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

      final client = ref.watch(mediaServerClientProvider);
      if (!client.capabilities.similarAlbums) return const [];

      final response = await client.getSimilarAlbums(albumId);
      return response.items.where((album) => album.id != albumId).toList();
    });
