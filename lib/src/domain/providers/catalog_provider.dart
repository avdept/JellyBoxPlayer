import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/http/user_agent.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/catalog_cache_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:optional_features/catalog.dart';

export 'package:optional_features/catalog.dart';

typedef LibraryArtistKey = ({String artistId, String name});

typedef SimilarArtist = ({CatalogArtist artist, LibraryItem? owned});

const similarArtistsLimit = 16;
const noMatchRetryAfter = Duration(days: 7);

final installedCatalogSourcesProvider = Provider<List<CatalogSource>>((ref) {
  final cache = ref.watch(catalogCacheDatabaseProvider);
  unawaited(_pruneQuietly(cache));
  return catalogSources(cache: cache, userAgent: jellyboxUserAgent());
});

final catalogAvailableProvider = Provider<bool>(
  (ref) => ref.watch(installedCatalogSourcesProvider).isNotEmpty,
);

final catalogSourcesProvider = Provider<List<CatalogSource>>((ref) {
  if (ref.watch(isOfflineProvider)) return const [];
  if (!ref.watch(settingProvider(AppSetting.catalogDiscovery))) {
    return const [];
  }
  return ref.watch(installedCatalogSourcesProvider);
});

final ProviderFamily<CatalogSource?, String> catalogSourceProvider =
    Provider.family<CatalogSource?, String>(
      (ref, id) => ref
          .watch(catalogSourcesProvider)
          .where((source) => source.id == id)
          .firstOrNull,
    );

final ProviderFamily<CatalogBrand?, String> catalogBrandProvider =
    Provider.family<CatalogBrand?, String>(
      (ref, id) => ref
          .watch(installedCatalogSourcesProvider)
          .where((source) => source.id == id)
          .firstOrNull
          ?.brand,
    );

final AutoDisposeFutureProviderFamily<List<String>, String>
libraryAlbumTitlesProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, artistId) async {
      if (ref.watch(currentUserProvider) == null) return const [];
      final albums = await ref
          .watch(mediaServerClientProvider)
          .getAlbums(LibraryQuery(artistIds: [artistId], limit: 200));
      return [for (final album in albums.items) album.name];
    });

final AutoDisposeFutureProviderFamily<CatalogKey?, LibraryArtistKey>
catalogMatchProvider = FutureProvider.autoDispose
    .family<CatalogKey?, LibraryArtistKey>((ref, key) async {
      final source = ref.watch(catalogSourcesProvider).firstOrNull;
      if (source == null) return null;
      if (ref.watch(currentUserProvider) == null) return null;

      final links = ref.watch(catalogCacheDatabaseProvider);
      final link = await _readLink(links, key.artistId, source.id);
      if (link != null) {
        final catalogId = link.catalogId;
        if (catalogId != null) return (source: source.id, id: catalogId);
        if (DateTime.now().difference(link.checkedAt) < noMatchRetryAfter) {
          return null;
        }
      }

      final titles = await ref.watch(
        libraryAlbumTitlesProvider(key.artistId).future,
      );
      final match = await source.findArtist(key.name, albumTitles: titles);
      await _saveLink(links, key.artistId, source.id, match?.id);
      return match?.key;
    });

final AutoDisposeFutureProviderFamily<List<SimilarArtist>, LibraryArtistKey>
similarArtistsProvider = FutureProvider.autoDispose
    .family<List<SimilarArtist>, LibraryArtistKey>((ref, key) async {
      final match = await ref.watch(catalogMatchProvider(key).future);
      if (match == null) return const [];
      return ref.watch(catalogRelatedArtistsProvider(match).future);
    });

final AutoDisposeFutureProviderFamily<List<SimilarArtist>, CatalogKey>
catalogRelatedArtistsProvider = FutureProvider.autoDispose
    .family<List<SimilarArtist>, CatalogKey>((ref, key) async {
      final source = ref.watch(catalogSourceProvider(key.source));
      if (source == null) return const [];

      final related = await source.relatedArtists(
        key.id,
        limit: similarArtistsLimit,
      );
      if (ref.watch(currentUserProvider) == null) {
        return [for (final artist in related) (artist: artist, owned: null)];
      }

      final client = ref.watch(mediaServerClientProvider);
      final owned = await Future.wait(
        related.map((artist) => libraryArtistNamed(client, artist.name)),
      );
      return [
        for (var i = 0; i < related.length; i++)
          (artist: related[i], owned: owned[i]),
      ];
    });

final AutoDisposeFutureProviderFamily<List<CatalogAlbum>, CatalogKey>
catalogAlbumsProvider = FutureProvider.autoDispose
    .family<List<CatalogAlbum>, CatalogKey>((ref, key) async {
      final source = ref.watch(catalogSourceProvider(key.source));
      return source == null ? const [] : source.albums(key.id);
    });

final AutoDisposeFutureProviderFamily<CatalogAlbumDetail?, CatalogKey>
catalogAlbumProvider = FutureProvider.autoDispose
    .family<CatalogAlbumDetail?, CatalogKey>((ref, key) async {
      final source = ref.watch(catalogSourceProvider(key.source));
      return source?.album(key.id);
    });

const Set<CatalogReleaseType> missingAlbumTypes = {
  CatalogReleaseType.album,
  CatalogReleaseType.ep,
};

final AutoDisposeFutureProviderFamily<List<CatalogAlbum>, LibraryArtistKey>
missingAlbumsProvider = FutureProvider.autoDispose
    .family<List<CatalogAlbum>, LibraryArtistKey>((ref, key) async {
      final match = await ref.watch(catalogMatchProvider(key).future);
      if (match == null) return const [];
      final titles = await ref.watch(
        libraryAlbumTitlesProvider(key.artistId).future,
      );
      final albums = await ref.watch(catalogAlbumsProvider(match).future);
      return missingAlbums(albums, ownedTitles: titles);
    });

List<CatalogAlbum> missingAlbums(
  List<CatalogAlbum> albums, {
  required Iterable<String> ownedTitles,
}) {
  final owned = {for (final title in ownedTitles) normalizeCatalogName(title)};
  final seen = <String>{};
  final missing = <CatalogAlbum>[];
  for (final album in albums) {
    if (!missingAlbumTypes.contains(album.releaseType)) continue;
    final title = normalizeCatalogName(album.title);
    final base = normalizeCatalogName(_baseTitle(album.title));
    if (owned.contains(title) || owned.contains(base)) continue;
    if (!seen.add(base)) continue;
    missing.add(album);
  }
  missing.sort((a, b) {
    final left = a.releaseDate;
    final right = b.releaseDate;
    if (left == null && right == null) return 0;
    if (left == null || right == null) return left == null ? 1 : -1;
    return right.compareTo(left);
  });
  return missing;
}

String _baseTitle(String title) =>
    title.replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]\s*$'), '').trim();

Future<LibraryItem?> libraryArtistNamed(
  MediaServerClient client,
  String name,
) async {
  final wanted = normalizeCatalogName(name);
  if (wanted.isEmpty) return null;
  try {
    final page = await client.searchArtists(SearchQuery(term: name, limit: 10));
    return page.items
        .where((item) => normalizeCatalogName(item.name) == wanted)
        .firstOrNull;
  } on Object {
    return null;
  }
}

Future<CatalogArtistLink?> _readLink(
  CatalogCacheDatabase links,
  String artistId,
  String source,
) async {
  try {
    return await links.artistLink(artistId, source);
  } on Object catch (error) {
    debugPrint('[Catalog] could not read artist link: $error');
    return null;
  }
}

Future<void> _saveLink(
  CatalogCacheDatabase links,
  String artistId,
  String source,
  String? catalogId,
) async {
  try {
    await links.saveArtistLink(artistId, source, catalogId: catalogId);
  } on Object catch (error) {
    debugPrint('[Catalog] could not save artist link: $error');
  }
}

Future<void> _pruneQuietly(CatalogCacheDatabase cache) async {
  try {
    await cache.prune();
  } on Object catch (error) {
    debugPrint('[Catalog] could not prune the cache: $error');
  }
}
