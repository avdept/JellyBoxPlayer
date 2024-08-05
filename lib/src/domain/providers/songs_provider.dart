import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';

class SongsNotifier extends StateNotifier<AsyncData<List<SongDTO>>> {
  SongsNotifier(
    this.ref,
    this.filterState, {
    this.albumId,
    this.filters,
  }) : super(const AsyncData([]));

  final String? albumId;
  final StateNotifierProviderRef<SongsNotifier, AsyncData<List<SongDTO>>> ref;
  final Filter filterState;
  final String? filters;

  Future<void> loadMore() async {
    final resp = await ref.read(jellyfinApiProvider).getSongs(
          userId: ref.read(currentUserProvider)!.userId,
          albumId: albumId,
          filters: filters,
        );
    state = AsyncData(
      List.from(resp.data.items)
        ..sort((a, b) => a.indexNumber.compareTo(b.indexNumber)),
    );
  }
}

final songsProvider = StateNotifierProvider.family<SongsNotifier,
    AsyncData<List<SongDTO>>, String>(
  (ref, albumId) => SongsNotifier(
    ref,
    ref.watch(filterProvider),
    albumId: albumId,
  )..loadMore(),
);

final favoriteSongsProvider =
    StateNotifierProvider<SongsNotifier, AsyncData<List<SongDTO>>>(
  (ref) => SongsNotifier(
    ref,
    ref.watch(filterProvider),
    filters: 'IsFavorite',
  )..loadMore(),
);
