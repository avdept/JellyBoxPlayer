import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

class CurrentPlaylistNotifier extends StateNotifier<ItemDTO?> {
  CurrentPlaylistNotifier(this._ref) : super(null) {
    final keepAliveLink = _ref.keepAlive();
    _ref.onDispose(keepAliveLink.close);

    _api = _ref.watch(jellyfinApiProvider);
  }

  final Ref _ref;
  late JellyfinApi _api;

  void setPlaylist(ItemDTO playlist) {
    state = playlist;
  }

  // TODO: should be moved to a separate provider
  Future<ItemsWrapper> fetchSongs(String playlistId) async {
    try {
      final songs = await _api.getSongs(
        userId: _ref.read(currentUserProvider)!.userId,
        albumId: playlistId,
      );
      return songs.data;
    } on DioException catch (e) {
      log(e.message ?? 'Error while fetching Songs');
    }
    return const ItemsWrapper(items: []);
  }
}

final AutoDisposeStateNotifierProvider<CurrentPlaylistNotifier, ItemDTO?>
currentPlaylistProvider = StateNotifierProvider.autoDispose(
  CurrentPlaylistNotifier.new,
);
