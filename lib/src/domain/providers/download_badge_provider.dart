import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';

enum DownloadBadge { downloaded, downloading }

typedef DownloadedCollections = ({Set<String> albums, Set<String> playlists});

final downloadedCollectionsProvider = FutureProvider<DownloadedCollections>((
  ref,
) async {
  ref.listen(downloadManagerProvider, (prev, now) {
    if (prev?.valueOrNull != now.valueOrNull) ref.invalidateSelf();
  });
  final database = ref.watch(downloadDatabaseProvider);
  final (albums, playlists) = await (
    database.albumIds(),
    database.playlistIds(),
  ).wait;
  return (albums: albums, playlists: playlists);
});

final ProviderFamily<DownloadBadge?, (ItemKind, String)> downloadBadgeProvider =
    Provider.family<DownloadBadge?, (ItemKind, String)>((ref, key) {
      final (kind, id) = key;
      if (kind != ItemKind.album && kind != ItemKind.playlist) return null;
      if (ref.watch(
        activeDownloadsProvider.select((active) => active.containsKey(id)),
      )) {
        return DownloadBadge.downloading;
      }
      final downloaded = ref.watch(
        downloadedCollectionsProvider.select((collections) {
          final value = collections.valueOrNull;
          if (value == null) return false;
          final ids = kind == ItemKind.album ? value.albums : value.playlists;
          return ids.contains(id);
        }),
      );
      return downloaded ? DownloadBadge.downloaded : null;
    });

final ProviderFamily<double?, String> downloadProgressProvider =
    Provider.family<double?, String>(
      (ref, id) => ref.watch(
        activeDownloadsProvider.select((active) => active[id]),
      ),
    );
