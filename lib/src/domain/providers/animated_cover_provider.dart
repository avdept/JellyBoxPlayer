import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/animated_cover_database_provider.dart';
import 'package:jplayer/src/data/storages/animated_cover_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/now_playing_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const animatedCoverRetryAfter = Duration(days: 30);

typedef AnimatedCoverQuery = ({String artist, String album});

final AutoDisposeFutureProviderFamily<Uri?, AnimatedCoverQuery>
animatedCoverSearchProvider = FutureProvider.autoDispose
    .family<Uri?, AnimatedCoverQuery>((ref, query) async {
      final store = ref.watch(animatedCoverDatabaseProvider);
      final key = AnimatedCoverDatabase.keyFor(
        artist: query.artist,
        album: query.album,
      );
      final cached = await store.get(key);
      if (cached != null) {
        final fresh =
            cached.url != null ||
            DateTime.now().difference(cached.checkedAt) <
                animatedCoverRetryAfter;
        if (fresh) return cached.url;
      }
      if (ref.read(isOfflineProvider)) return cached?.url;

      try {
        final found = await ref
            .read(animatedArtworkClientProvider)
            .search(artist: query.artist, album: query.album);
        await store.put(key, found?.url);
        return found?.url;
      } on Object catch (error) {
        debugPrint(
          '[AnimatedCover] lookup failed for "${query.album}": $error',
        );
        return cached?.url;
      }
    });

final AutoDisposeFutureProviderFamily<Uri?, LibraryItem> animatedCoverProvider =
    FutureProvider.autoDispose.family<Uri?, LibraryItem>((
      ref,
      album,
    ) async {
      if (!ref.watch(settingProvider(AppSetting.animatedCovers))) return null;
      final artist = album.albumArtist ?? album.albumArtists.firstOrNull?.name;
      if (artist == null || artist.isEmpty || album.name.isEmpty) return null;
      return ref.watch(
        animatedCoverSearchProvider((artist: artist, album: album.name)).future,
      );
    });

final AutoDisposeFutureProvider<Uri?> nowPlayingAnimatedCoverProvider =
    FutureProvider.autoDispose<Uri?>((ref) async {
      if (!ref.watch(settingProvider(AppSetting.studioModeVideoCovers))) {
        return null;
      }
      final (artist, album) = ref.watch(
        nowPlayingProvider.select((song) => (song?.artist, song?.album)),
      );
      if (artist == null || artist.isEmpty || album == null || album.isEmpty) {
        return null;
      }
      return ref.watch(
        animatedCoverSearchProvider((artist: artist, album: album)).future,
      );
    });
