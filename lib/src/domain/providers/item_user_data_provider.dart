import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

class ItemUserDataNotifier
    extends AutoDisposeFamilyAsyncNotifier<SongUserData, String> {
  late String _currentUserId;

  @override
  FutureOr<SongUserData> build(String arg) async {
    _currentUserId = ref.watch(currentUserProvider)!.userId;
    final response = await ref.read(jellyfinApiProvider).getItemUserData(
          itemId: arg,
          userId: _currentUserId,
        );
    return response.data;
  }

  Future<void> toggleFavorite(bool isFavorite) async {
    state = const AsyncLoading();
    final response = await ref.read(jellyfinApiProvider).updateItemUserData(
          state.value!.copyWith(isFavorite: isFavorite),
          itemId: arg,
          userId: _currentUserId,
        );
    state = AsyncData(response.data);
  }
}

final itemUserDataProvider = AutoDisposeAsyncNotifierProvider.family<
    ItemUserDataNotifier, SongUserData, String>(
  ItemUserDataNotifier.new,
);
