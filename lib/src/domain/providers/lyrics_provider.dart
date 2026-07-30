import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

final lyricsProvider = FutureProviderFamily<LyricsDTO?, String>(
  (ref, itemId) async {
    if (ref.watch(isOfflineProvider)) return null;
    final api = ref.watch(jellyfinApiProvider);
    try {
      final response = await api.getLyrics(itemId: itemId);
      return response.data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 400) return null;
      log(e.message ?? 'Error while fetching lyrics for $itemId');
      rethrow;
    }
  },
);

final lyricsVisibleProvider = StateProvider<bool>((ref) => false);

final lyricsShownProvider = Provider<bool>((ref) {
  if (!ref.watch(lyricsVisibleProvider)) return false;
  return ref.watch(
    playbackProvider.select((state) {
      final index = state.currentMediaIndex;
      if (index == null) return false;
      return state.songs.elementAtOrNull(index)?.hasLyrics ?? false;
    }),
  );
});
