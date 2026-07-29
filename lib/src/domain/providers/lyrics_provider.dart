import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';

/// Lyric lines for a single track, or null when the server has none for it.
///
/// Requires Jellyfin 10.9 or newer. Word level cues are only filled in by
/// 10.11 and newer.
final lyricsProvider = FutureProviderFamily<LyricsDTO?, String>(
  (ref, itemId) async {
    final api = ref.watch(jellyfinApiProvider);
    try {
      final response = await api.getLyrics(itemId: itemId);
      return response.data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 404: no lyrics for this track. 400: server predates the endpoint.
      if (status == 404 || status == 400) return null;
      log(e.message ?? 'Error while fetching lyrics for $itemId');
      rethrow;
    }
  },
);

/// Whether lyrics are being shown instead of the artwork (in the player
/// sheet) or over the main content area (on desktop).
final lyricsVisibleProvider = StateProvider<bool>((ref) => false);
