import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/animated_cover_database_provider.dart';
import 'package:jplayer/src/data/storages/animated_cover_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const animatedCoverRetryAfter = Duration(days: 30);

final AutoDisposeFutureProviderFamily<Uri?, LibraryItem>
animatedCoverProvider = FutureProvider.autoDispose.family<Uri?, LibraryItem>((
  ref,
  album,
) async {
  if (!ref.watch(settingProvider(AppSetting.animatedCovers))) return null;
  final artist = album.albumArtist ?? album.albumArtists.firstOrNull?.name;
  if (artist == null || artist.isEmpty || album.name.isEmpty) return null;

  final store = ref.watch(animatedCoverDatabaseProvider);
  final key = AnimatedCoverDatabase.keyFor(artist: artist, album: album.name);
  final cached = await store.get(key);
  if (cached != null) {
    final fresh =
        cached.url != null ||
        DateTime.now().difference(cached.checkedAt) < animatedCoverRetryAfter;
    if (fresh) return cached.url;
  }
  if (ref.read(isOfflineProvider)) return cached?.url;

  try {
    final found = await ref
        .read(animatedArtworkClientProvider)
        .search(artist: artist, album: album.name);
    await store.put(key, found?.url);
    return found?.url;
  } on Object catch (error) {
    debugPrint('[AnimatedCover] lookup failed for "${album.name}": $error');
    return cached?.url;
  }
});
