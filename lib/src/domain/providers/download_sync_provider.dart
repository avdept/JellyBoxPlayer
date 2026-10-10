import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/playlist_songs_source.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/network_type_provider.dart';

class DownloadSync {
  DownloadSync(this._ref) {
    _ref
      ..listen<bool>(isOfflineProvider, (previous, next) {
        if (previous != next && !next) syncAll();
      })
      ..listen<NetworkType>(networkTypeProvider, (previous, next) {
        if (previous != next && next == NetworkType.wifi) syncAll();
      })
      ..listen<bool>(settingProvider(AppSetting.downloadSyncOnCellular), (
        previous,
        next,
      ) {
        if (previous != next && next) syncAll();
      })
      ..listen<User?>(currentUserProvider, (previous, next) {
        if (next != null && next.userId != previous?.userId) syncAll();
      })
      ..listen<int>(favouritesChangedProvider, (previous, next) {
        if (previous != next) syncLikedSongs();
      })
      ..listen<ContentUpdateInterval>(
        contentUpdateIntervalProvider,
        (_, interval) => _schedule(interval),
        fireImmediately: true,
      );
    _lifecycleListener = AppLifecycleListener(
      onResume: () => syncAll(throttled: true),
    );
    syncAll();
  }

  final Ref _ref;
  final _requested = <String>{};
  late final AppLifecycleListener _lifecycleListener;
  Timer? _timer;
  Duration? _interval;
  DateTime? _lastFullSync;
  var _all = false;
  var _draining = false;
  var _disposed = false;

  void _schedule(ContentUpdateInterval interval) {
    _timer?.cancel();
    _interval = interval.duration;
    final duration = _interval;
    if (duration == null) return;
    _timer = Timer.periodic(duration, (_) => syncAll());
  }

  void syncAll({bool throttled = false}) {
    if (throttled) {
      final interval = _interval;
      final last = _lastFullSync;
      if (interval == null) return;
      if (last != null && DateTime.now().difference(last) < interval) return;
    }
    _all = true;
    unawaited(_drain());
  }

  void syncPlaylist(String playlistId) {
    _requested.add(playlistId);
    unawaited(_drain());
  }

  void syncLikedSongs() {
    final liked = _ref.read(likedSongsPlaylistProvider);
    if (liked != null) syncPlaylist(liked.id);
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_all || _requested.isNotEmpty) {
        if (!await _canSync()) return;
        final manager = _ref.read(downloadManagerProvider.notifier);
        final downloaded = await manager.getDownloadedPlaylists();
        final everything = _all;
        final requested = {..._requested};
        _all = false;
        _requested.clear();
        if (everything) _lastFullSync = DateTime.now();

        for (final playlist in downloaded) {
          if (!everything && !requested.contains(playlist.item.id)) continue;
          if (!await _canSync()) return;
          await _syncOne(manager, playlist.item);
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<bool> _canSync() async {
    if (_disposed) return false;
    if (_ref.read(isOfflineProvider)) return false;
    if (_ref.read(currentUserProvider) == null) return false;
    if (_ref.read(settingProvider(AppSetting.downloadSyncOnCellular))) {
      return true;
    }
    await _ref.read(networkTypeProvider.notifier).ready;
    return _ref.read(networkTypeProvider) == NetworkType.wifi;
  }

  Future<void> _syncOne(
    DownloadManagerNotifier manager,
    LibraryItem playlist,
  ) async {
    final kind = EphemeralPlaylistId.parse(playlist.id)?.kind;
    if (kind == EphemeralPlaylistKind.likedSongs &&
        EphemeralPlaylistId.parse(playlist.id)!.key !=
            _ref.read(currentUserProvider)?.userId) {
      return;
    }
    try {
      final songs = await _ref
          .read(playlistSongsSourceProvider)
          .songsOf(playlist.id);
      if (songs.isEmpty) return;
      final changed = await manager.syncPlaylist(
        playlist,
        songs,
        keepLocalOrder: kind == EphemeralPlaylistKind.likedSongs,
      );
      if (changed) debugPrint('[DownloadSync] updated "${playlist.name}"');
    } on Object catch (error) {
      debugPrint('[DownloadSync] "${playlist.name}" failed: $error');
    }
  }

  void dispose() {
    _disposed = true;
    _lifecycleListener.dispose();
    _timer?.cancel();
  }
}

final downloadSyncProvider = Provider<DownloadSync>((ref) {
  final sync = DownloadSync(ref);
  ref.onDispose(sync.dispose);
  return sync;
});
