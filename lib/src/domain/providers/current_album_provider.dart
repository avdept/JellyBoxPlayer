import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

final currentAlbumProvider = StateNotifierProvider.autoDispose<CurrentAlbumNotifier, ItemDTO?>(
  (ref) {
    final notifier = CurrentAlbumNotifier(api: ref.read(jellyfinApiProvider), ref: ref);
    final keepAliveLink = ref.keepAlive();

    ref.onDispose(keepAliveLink.close);

    return notifier;
  },
);

class CurrentAlbumNotifier extends StateNotifier<ItemDTO?> {
  CurrentAlbumNotifier({required JellyfinApi api, required AutoDisposeStateNotifierProviderRef<CurrentAlbumNotifier, ItemDTO?> ref})
      : _api = api,
        _ref = ref,
        super(null);

  final JellyfinApi _api;
  final String libraryIdStorageKey = 'library_id';
  final String libraryPathStorageKey = 'library_path';
  final AutoDisposeStateNotifierProviderRef<CurrentAlbumNotifier, ItemDTO?> _ref;

  void setAlbum(ItemDTO album) {
    state = album;
  }

  Future<SongsWrapper> fetchSongs(String albumId) async {
    try {
      final songs = await _api.getSongs(userId: _ref.read(currentUserProvider.notifier).state!.userId, albumId: albumId);
      return songs.data;
    } on DioException catch (e) {
      log(e.message ?? "Error while fetching Songs");
    }
    return SongsWrapper(items: []);
  }
}
