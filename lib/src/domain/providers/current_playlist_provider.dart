import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

class CurrentPlaylistNotifier extends StateNotifier<LibraryItem?> {
  CurrentPlaylistNotifier(this._ref) : super(null) {
    final keepAliveLink = _ref.keepAlive();
    _ref.onDispose(keepAliveLink.close);

    _client = _ref.watch(mediaServerClientProvider);
  }

  final Ref _ref;
  late MediaServerClient _client;

  void setPlaylist(LibraryItem playlist) {
    state = playlist;
  }

  // TODO: should be moved to a separate provider
  Future<LibraryPage> fetchSongs(String playlistId) async {
    try {
      return await _client.getSongs(
        userId: _ref.read(currentUserProvider)!.userId,
        albumId: playlistId,
      );
    } on DioException catch (e) {
      log(e.message ?? 'Error while fetching Songs');
    }
    return const LibraryPage(items: []);
  }
}

final AutoDisposeStateNotifierProvider<CurrentPlaylistNotifier, LibraryItem?>
currentPlaylistProvider = StateNotifierProvider.autoDispose(
  CurrentPlaylistNotifier.new,
);
