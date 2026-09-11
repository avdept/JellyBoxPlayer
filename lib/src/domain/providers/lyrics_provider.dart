import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/studio_mode_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

final lyricsProvider = FutureProviderFamily<Lyrics?, String>((ref, itemId) {
  if (ref.watch(isOfflineProvider)) return Future.value();
  final client = ref.watch(mediaServerClientProvider);
  if (!client.capabilities.lyrics) return Future.value();
  return client.getLyrics(itemId);
});

final lyricsVisibleProvider = StateProvider<bool>((ref) => false);

final lyricsShownProvider = Provider<bool>((ref) {
  if (!ref.watch(lyricsVisibleProvider)) return false;
  if (ref.watch(studioModeVisibleProvider)) return false;
  return ref.watch(
    currentSongProvider.select((song) => song?.hasLyrics ?? false),
  );
});
