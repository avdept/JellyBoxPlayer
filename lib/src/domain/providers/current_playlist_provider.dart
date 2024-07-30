import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

final currentPlaylistProvider = StateNotifierProvider.autoDispose<CurrentPlaylistNotifier, ItemDTO?>(
  (ref) {
    final notifier = CurrentPlaylistNotifier(api: ref.read(jellyfinApiProvider), ref: ref);
    final keepAliveLink = ref.keepAlive();

    ref.onDispose(keepAliveLink.close);

    return notifier;
  },
);

class CurrentPlaylistNotifier extends StateNotifier<ItemDTO?> {
  CurrentPlaylistNotifier({required JellyfinApi api, required AutoDisposeStateNotifierProviderRef<CurrentPlaylistNotifier, ItemDTO?> ref})
      : _api = api,
        _ref = ref,
        super(null);

  final JellyfinApi _api;
  final String libraryIdStorageKey = 'library_id';
  final String libraryPathStorageKey = 'library_path';
  final AutoDisposeStateNotifierProviderRef<CurrentPlaylistNotifier, ItemDTO?> _ref;

  void setPlaylist(ItemDTO playlist) {
    state = playlist;
  }

  Future<SongsWrapper> fetchSongs(String playlistId) async {
    try {
      final songs = await _api.getSongs(userId: _ref.read(currentUserProvider.notifier).state!.userId, albumId: playlistId);
      return songs.data;
    } on DioException catch (e) {
      log(e.message ?? "Error while fetching Songs");
    }
    return SongsWrapper(items: []);
  }
}
