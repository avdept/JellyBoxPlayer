import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

class CurrentAlbumNotifier extends StateNotifier<LibraryItem?> {
  CurrentAlbumNotifier(this._ref) : super(null) {
    final keepAliveLink = _ref.keepAlive();
    _ref.onDispose(keepAliveLink.close);

    _client = _ref.watch(mediaServerClientProvider);
  }

  final Ref _ref;
  late MediaServerClient _client;

  void setAlbum(LibraryItem album) {
    state = album;
  }

  // TODO: should be moved to a separate provider
  Future<LibraryPage> fetchSongs(String albumId) async {
    try {
      return await _client.getSongs(
        userId: _ref.read(currentUserProvider)!.userId,
        albumId: albumId,
      );
    } on DioException catch (e) {
      log(e.message ?? 'Error while fetching Songs');
    }
    return const LibraryPage(items: []);
  }
}

final AutoDisposeStateNotifierProvider<CurrentAlbumNotifier, LibraryItem?>
currentAlbumProvider = StateNotifierProvider.autoDispose(
  CurrentAlbumNotifier.new,
);
