import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/lyrics/lrclib_client.dart';
import 'package:jplayer/src/core/lyrics/lrclib_lyrics_source.dart';
import 'package:jplayer/src/core/lyrics/lyrics_source.dart';
import 'package:jplayer/src/core/lyrics/server_lyrics_source.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/domain/providers/studio_mode_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

final lrclibClientProvider = Provider<LrclibClient>(
  (ref) => LrclibClient(userAgent: _userAgent()),
);

String _userAgent() {
  const project = 'https://github.com/avdept/JellyBoxPlayer';
  try {
    return 'JellyBox v${appInfo.version} ($project)';
  } catch (_) {
    return 'JellyBox ($project)';
  }
}

final lyricsSourcesProvider = Provider<List<LyricsSource>>(
  (ref) => [
    if (ref.watch(serverCapabilitiesProvider).lyrics)
      ServerLyricsSource(ref.watch(mediaServerClientProvider)),
    if (ref.watch(settingProvider(AppSetting.lrclibLyrics)))
      LrclibLyricsSource(ref.watch(lrclibClientProvider)),
  ],
);

final lyricsProvider = FutureProviderFamily<Lyrics?, String>((ref, itemId) {
  if (ref.watch(isOfflineProvider)) return Future.value();
  final sources = ref.watch(lyricsSourcesProvider);
  if (sources.isEmpty) return Future.value();
  final song = ref.read(barSongProvider);
  final request = song != null && song.id == itemId
      ? LyricsRequest.forSong(song)
      : LyricsRequest(itemId: itemId);
  return resolveLyrics(sources, request);
});

final lyricsVisibleProvider = StateProvider<bool>((ref) => false);

final currentSongHasLyricsProvider = Provider<bool>((ref) {
  final song = ref.watch(barSongProvider);
  if (song == null) return false;
  final lyrics = ref.watch(lyricsProvider(song.id));
  if (!lyrics.hasValue) return song.hasLyrics;
  return lyrics.value?.lines.isNotEmpty ?? false;
});

final lyricsShownProvider = Provider<bool>((ref) {
  if (!ref.watch(lyricsVisibleProvider)) return false;
  if (ref.watch(studioModeVisibleProvider)) return false;
  return ref.watch(currentSongHasLyricsProvider);
});
