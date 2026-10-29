import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/http/user_agent.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/storages/keychain_access.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/musicbrainz_provider.dart';
import 'package:optional_features/catalog.dart';
import 'package:optional_features/lidarr.dart';

sealed class LidarrTarget {
  const LidarrTarget();

  String get title;
}

class LidarrAlbumTarget extends LidarrTarget {
  const LidarrAlbumTarget(this.album);

  final CatalogAlbum album;

  @override
  String get title => album.title;
}

class LidarrArtistTarget extends LidarrTarget {
  const LidarrArtistTarget(this.artist);

  final CatalogArtist artist;

  @override
  String get title => artist.name;
}

enum LidarrStatus { loading, disconnected, connecting, connected, rejected }

class LidarrAccount {
  const LidarrAccount({
    required this.status,
    this.url = '',
    this.apiKey = '',
    this.version,
    this.error,
  });

  final LidarrStatus status;
  final String url;
  final String apiKey;
  final String? version;
  final String? error;

  bool get isConnected => status == LidarrStatus.connected;
}

class LidarrAccountNotifier extends StateNotifier<LidarrAccount> {
  LidarrAccountNotifier(Ref ref, {bool restore = true})
    : _ref = ref,
      super(const LidarrAccount(status: LidarrStatus.loading)) {
    if (restore) unawaited(_restore());
  }

  static const apiKeyKey = 'lidarr_api_key';
  static const _disconnected = LidarrAccount(status: LidarrStatus.disconnected);

  final Ref _ref;
  var _attempt = 0;

  Future<void> _restore() async {
    final attempt = _attempt;
    try {
      await _ref.read(sharedPreferencesProvider.future);
      final url = _ref
          .read(appSettingsProvider.notifier)
          .valueOf(AppSetting.lidarrUrl);
      final apiKey = await KeychainAccess(
        _ref.read(secureStorageProvider),
      ).readSessionKey(apiKeyKey);
      if (!mounted || attempt != _attempt) return;
      if (url.isNotEmpty && apiKey != null && apiKey.isNotEmpty) {
        state = LidarrAccount(
          status: LidarrStatus.connected,
          url: url,
          apiKey: apiKey,
        );
        return;
      }
    } on Object catch (error) {
      debugPrint('[Lidarr] restoring the connection failed: $error');
    }
    if (mounted && attempt == _attempt) state = _disconnected;
  }

  Future<bool> connect(String url, String apiKey) async {
    final base = LidarrClient.normalizeBaseUrl(url);
    final key = apiKey.trim();
    if (base.isEmpty) return _fail('Enter the address of your Lidarr server');
    if (key.isEmpty) return _fail('Enter the Lidarr API key');

    final attempt = ++_attempt;
    state = LidarrAccount(status: LidarrStatus.connecting, url: base);
    final String version;
    try {
      version = (await _client(base, key).status()).version;
    } on LidarrException catch (error) {
      return _fail(error.message, url: base);
    } on Object catch (error) {
      return _fail('Could not reach Lidarr: $error', url: base);
    }
    if (!mounted || attempt != _attempt) return false;
    try {
      await _ref.read(secureStorageProvider).write(key: apiKeyKey, value: key);
    } on Object catch (error) {
      debugPrint('[Lidarr] could not store the API key: $error');
    }
    _ref
        .read(appSettingsProvider.notifier)
        .setValue(AppSetting.lidarrUrl, base);
    if (!mounted || attempt != _attempt) return false;
    state = LidarrAccount(
      status: LidarrStatus.connected,
      url: base,
      apiKey: key,
      version: version,
    );
    return true;
  }

  Future<void> disconnect() async {
    _attempt++;
    state = _disconnected;
    _ref.read(appSettingsProvider.notifier)
      ..setValue(AppSetting.lidarrUrl, '')
      ..setValue(AppSetting.lidarrRootFolder, '')
      ..setValue(AppSetting.lidarrQualityProfile, '')
      ..setValue(AppSetting.lidarrMetadataProfile, '');
    try {
      await _ref.read(secureStorageProvider).delete(key: apiKeyKey);
    } on Object catch (error) {
      debugPrint('[Lidarr] could not remove the API key: $error');
    }
  }

  bool _fail(String message, {String url = ''}) {
    if (mounted) {
      state = LidarrAccount(
        status: LidarrStatus.rejected,
        url: url,
        error: message,
      );
    }
    return false;
  }

  LidarrClient? get client =>
      state.isConnected ? _client(state.url, state.apiKey) : null;

  LidarrClient _client(String url, String apiKey) => LidarrClient(
    baseUrl: url,
    apiKey: apiKey,
    userAgent: jellyboxUserAgent(),
  );
}

final lidarrAvailableProvider = Provider<bool>(
  (ref) => LidarrClient(baseUrl: '', apiKey: '').available,
);

final lidarrAccountProvider =
    StateNotifierProvider<LidarrAccountNotifier, LidarrAccount>(
      LidarrAccountNotifier.new,
    );

final lidarrClientProvider = Provider<LidarrClient?>((ref) {
  final account = ref.watch(lidarrAccountProvider);
  if (!account.isConnected) return null;
  return LidarrClient(
    baseUrl: account.url,
    apiKey: account.apiKey,
    userAgent: jellyboxUserAgent(),
  );
});

class LidarrOptions {
  const LidarrOptions({
    required this.rootFolders,
    required this.qualityProfiles,
    required this.metadataProfiles,
  });

  final List<LidarrRootFolder> rootFolders;
  final List<LidarrProfile> qualityProfiles;
  final List<LidarrProfile> metadataProfiles;
}

final AutoDisposeFutureProvider<LidarrOptions?> lidarrOptionsProvider =
    FutureProvider.autoDispose<LidarrOptions?>((
      ref,
    ) async {
      final client = ref.watch(lidarrClientProvider);
      if (client == null) return null;
      final results = await Future.wait([
        client.rootFolders(),
        client.qualityProfiles(),
        client.metadataProfiles(),
      ]);
      return LidarrOptions(
        rootFolders: results[0] as List<LidarrRootFolder>,
        qualityProfiles: results[1] as List<LidarrProfile>,
        metadataProfiles: results[2] as List<LidarrProfile>,
      );
    });

class LidarrPlacement {
  const LidarrPlacement({
    required this.defaults,
    required this.rootFolder,
    required this.qualityProfile,
    required this.metadataProfile,
  });

  final LidarrAddDefaults defaults;
  final LidarrRootFolder rootFolder;
  final LidarrProfile? qualityProfile;
  final LidarrProfile? metadataProfile;
}

final AutoDisposeFutureProvider<LidarrPlacement?> lidarrPlacementProvider =
    FutureProvider.autoDispose<LidarrPlacement?>((
      ref,
    ) async {
      final options = await ref.watch(lidarrOptionsProvider.future);
      if (options == null || options.rootFolders.isEmpty) return null;
      final settings = ref.watch(appSettingsProvider.notifier);
      final rootPath = settings.valueOf(AppSetting.lidarrRootFolder);
      final root = options.rootFolders
          .where((folder) => folder.path == rootPath)
          .firstOrNull;
      final rootFolder = root ?? options.rootFolders.first;

      LidarrProfile? pick(
        List<LidarrProfile> profiles,
        AppSetting setting,
        int fallback,
      ) {
        final chosen = int.tryParse(settings.valueOf(setting));
        return profiles.where((p) => p.id == chosen).firstOrNull ??
            profiles.where((p) => p.id == fallback).firstOrNull ??
            profiles.firstOrNull;
      }

      final quality = pick(
        options.qualityProfiles,
        AppSetting.lidarrQualityProfile,
        rootFolder.defaultQualityProfileId,
      );
      final metadata = pick(
        options.metadataProfiles,
        AppSetting.lidarrMetadataProfile,
        rootFolder.defaultMetadataProfileId,
      );
      if (quality == null || metadata == null) return null;
      return LidarrPlacement(
        defaults: LidarrAddDefaults(
          rootFolderPath: rootFolder.path,
          qualityProfileId: quality.id,
          metadataProfileId: metadata.id,
        ),
        rootFolder: rootFolder,
        qualityProfile: quality,
        metadataProfile: metadata,
      );
    });

enum LidarrEntityState { notAdded, added }

class LidarrEntityStatus {
  const LidarrEntityStatus(this.state);

  final LidarrEntityState state;
}

typedef LidarrAlbumKey = ({String? upc, String? artistName});

final AutoDisposeFutureProviderFamily<LidarrEntityStatus?, LidarrAlbumKey>
lidarrAlbumStatusProvider = FutureProvider.autoDispose
    .family<LidarrEntityStatus?, LidarrAlbumKey>((ref, key) async {
      final client = ref.watch(lidarrClientProvider);
      final upc = key.upc;
      if (client == null || upc == null || upc.isEmpty) return null;
      final match = await ref.watch(
        musicBrainzBarcodeMatchProvider((
          barcode: upc,
          artistName: key.artistName,
        )).future,
      );
      if (match == null) return null;
      final album = await client.albumByReleaseGroup(match.releaseGroupId);
      if (album == null) {
        return const LidarrEntityStatus(LidarrEntityState.notAdded);
      }
      return const LidarrEntityStatus(LidarrEntityState.added);
    });

final AutoDisposeFutureProvider<List<LidarrArtist>> lidarrArtistsProvider =
    FutureProvider.autoDispose<List<LidarrArtist>>((
      ref,
    ) async {
      final client = ref.watch(lidarrClientProvider);
      if (client == null) return const [];
      final link = ref.keepAlive();
      Timer(const Duration(minutes: 2), link.close);
      return client.artists();
    });

final AutoDisposeFutureProviderFamily<LidarrEntityStatus?, String>
lidarrArtistStatusProvider = FutureProvider.autoDispose
    .family<LidarrEntityStatus?, String>((ref, name) async {
      if (ref.watch(lidarrClientProvider) == null) return null;
      final wanted = normalizeCatalogName(name);
      final artists = await ref.watch(lidarrArtistsProvider.future);
      final match = artists
          .where((artist) => normalizeCatalogName(artist.name) == wanted)
          .firstOrNull;
      if (match == null) {
        return const LidarrEntityStatus(LidarrEntityState.notAdded);
      }
      return const LidarrEntityStatus(LidarrEntityState.added);
    });

class LidarrAddPlan {
  const LidarrAddPlan({
    required this.target,
    this.albums = const [],
    this.artists = const [],
    this.exact = false,
  });

  final LidarrTarget target;
  final List<LidarrAlbum> albums;
  final List<LidarrArtist> artists;
  final bool exact;

  int get candidateCount => albums.length + artists.length;
}

enum LidarrAddOutcome { added, alreadyAdded }

class LidarrAdder {
  LidarrAdder(this._ref);

  final Ref _ref;

  LidarrClient get _client {
    final client = _ref.read(lidarrClientProvider);
    if (client == null) throw const LidarrException('Lidarr is not connected');
    return client;
  }

  Future<LidarrAddPlan> plan(LidarrTarget target) => switch (target) {
    LidarrAlbumTarget(:final album) => _planAlbum(target, album),
    LidarrArtistTarget(:final artist) => _planArtist(target, artist),
  };

  Future<LidarrAddPlan> _planAlbum(
    LidarrTarget target,
    CatalogAlbum album,
  ) async {
    final upc = album.upc;
    if (upc != null && upc.isNotEmpty) {
      final match = await _ref.read(
        musicBrainzBarcodeMatchProvider((
          barcode: upc,
          artistName: album.artistName,
        )).future,
      );
      if (match != null) {
        final found = await _client.lookupAlbum(match.releaseGroupId);
        if (found != null) {
          return LidarrAddPlan(target: target, albums: [found], exact: true);
        }
      }
    }
    final term = [?album.artistName, album.title].join(' ');
    final results = await _client.searchAlbums(term);
    return LidarrAddPlan(target: target, albums: results.take(8).toList());
  }

  Future<LidarrAddPlan> _planArtist(
    LidarrTarget target,
    CatalogArtist artist,
  ) async {
    final wanted = normalizeCatalogName(artist.name);
    final results = await _client.searchArtists(artist.name);
    final exact = [
      for (final result in results)
        if (normalizeCatalogName(result.name) == wanted) result,
    ];
    final others = [
      for (final result in results)
        if (normalizeCatalogName(result.name) != wanted) result,
    ];
    return LidarrAddPlan(
      target: target,
      artists: [...exact, ...others].take(8).toList(),
      exact: exact.length == 1,
    );
  }

  Future<LidarrAddOutcome> addAlbum(
    LidarrAlbum album, {
    required LidarrAddDefaults defaults,
    required bool search,
  }) async {
    if (album.isAdded) return LidarrAddOutcome.alreadyAdded;
    await _client.addAlbum(album, defaults: defaults, search: search);
    _refreshStatuses();
    return LidarrAddOutcome.added;
  }

  Future<LidarrAddOutcome> addArtist(
    LidarrArtist artist, {
    required LidarrAddDefaults defaults,
    required bool search,
  }) async {
    if (artist.isAdded) return LidarrAddOutcome.alreadyAdded;
    await _client.addArtist(artist, defaults: defaults, search: search);
    _refreshStatuses();
    return LidarrAddOutcome.added;
  }

  void _refreshStatuses() {
    _ref
      ..invalidate(lidarrAlbumStatusProvider)
      ..invalidate(lidarrArtistsProvider)
      ..invalidate(lidarrArtistStatusProvider);
  }
}

final lidarrAdderProvider = Provider<LidarrAdder>(LidarrAdder.new);
