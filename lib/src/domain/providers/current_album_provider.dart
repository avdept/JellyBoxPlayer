import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/album/album_dto.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

final currentAlbumProvider = StateNotifierProvider.autoDispose<CurrentAlbumNotifier, AlbumDTO?>(
  (ref) {
    final notifier = CurrentAlbumNotifier(api: ref.read(jellyfinApiProvider), ref: ref);
    final keepAliveLink = ref.keepAlive();

    ref.onDispose(keepAliveLink.close);

    return notifier;
  },
);

class CurrentAlbumNotifier extends StateNotifier<AlbumDTO?> {
  CurrentAlbumNotifier({required JellyfinApi api, required AutoDisposeStateNotifierProviderRef<CurrentAlbumNotifier, AlbumDTO?> ref})
      : _api = api,
        _ref = ref,
        super(null);

  final JellyfinApi _api;
  final String libraryIdStorageKey = 'library_id';
  final String libraryPathStorageKey = 'library_path';
  final AutoDisposeStateNotifierProviderRef<CurrentAlbumNotifier, AlbumDTO?> _ref;

  void setAlbum(AlbumDTO album) {
    state = album;
  }

  Future<SongsWrapper> fetchSongs(String albumId) async {
    try {
      final songs = await _api.getSongs(userId: _ref.read(currentUserProvider.notifier).state!, albumId: albumId);
      return songs.data;
    } on DioException catch (e) {
      log(e.message ?? "Error while fetching Songs");
    }
    return SongsWrapper(items: []);
  }
}
