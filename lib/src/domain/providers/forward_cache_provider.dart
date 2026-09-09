import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/queue_cache_service.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class ForwardCacheNotifier extends StateNotifier<Set<String>> {
  ForwardCacheNotifier(this._ref) : super(const {}) {
    _ref.listen<ForwardCacheLimit>(
      forwardCacheLimitProvider,
      (previous, next) {
        if (previous != next) unawaited(_onLimitChanged(next));
      },
    );
    _ref.listen<ForwardCacheWindow>(forwardCacheWindowProvider, (
      previous,
      next,
    ) {
      if (previous != next) _schedule();
    });
    _ref.listen<PlaybackState>(playbackProvider, _onPlayback);
    _ref.listen<bool>(isOfflineProvider, (previous, next) {
      if (previous != next && !next) _schedule();
    });
    _schedule();
  }

  static const _assumedTrackLength = Duration(minutes: 4);

  final Ref _ref;
  final _inFlight = <String>{};
  final _failedIds = <String>{};

  late final Future<void> _ready = _bootstrap();

  QueueCacheService? _service;
  List<String> _lastQueueIds = const [];
  var _pumping = false;
  var _dirty = false;
  var _stopped = false;

  Future<void> _bootstrap() async {
    if (!mounted) return;
    try {
      await _currentService.reconcile();
      if (!mounted) return;
      await _applyLimit();
    } on Object catch (error) {
      debugPrint('[ForwardCache] bootstrap failed: $error');
    }
  }

  QueueCacheService get _currentService {
    final service = _ref.read(queueCacheServiceProvider);
    _service = service;
    return service;
  }

  void _schedule() {
    if (_pumping) {
      _dirty = true;
      return;
    }
    unawaited(_pump());
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      await _ready;
      do {
        _dirty = false;
        while (mounted) {
          final song = await _nextCandidate();
          if (song == null) break;
          await _fill(song);
        }
      } while (_dirty && mounted);
    } on Object catch (error) {
      debugPrint('[ForwardCache] fill loop failed: $error');
    } finally {
      _pumping = false;
    }
  }

  Future<void> _applyLimit() async {
    if (!mounted) return;
    final limit = _ref.read(forwardCacheLimitProvider);
    await _currentService.enforceLimit(limit.bytes, keepIds: _queueIds());
    await _refreshState();
  }

  Future<LibraryItem?> _nextCandidate() async {
    if (_stopped) return null;
    final limit = _ref.read(forwardCacheLimitProvider);
    if (!limit.isEnabled) return null;
    if (_ref.read(isOfflineProvider)) return null;
    if (!_ref.read(playbackProvider.notifier).supportsLocalFiles) return null;

    final database = _ref.read(queueCacheDatabaseProvider);
    final window = _candidates();
    if (window.isEmpty) return null;

    final present = await database.pathsFor([
      for (final song in window) song.id,
    ]);
    if (!mounted) return null;
    final pending = [
      for (final song in window)
        if (!present.containsKey(song.id) &&
            !_failedIds.contains(song.id) &&
            !_inFlight.contains(song.id))
          song,
    ];
    if (pending.isEmpty) return null;

    final downloaded = await _ref
        .read(downloadDatabaseProvider)
        .downloadedIds([for (final song in pending) song.id]);
    if (!mounted) return null;
    final wanted = [
      for (final song in pending)
        if (!downloaded.contains(song.id)) song,
    ];
    if (wanted.isEmpty) return null;

    if (!await _makeRoom(limit, window)) return null;
    return wanted.first;
  }

  Future<bool> _makeRoom(
    ForwardCacheLimit limit,
    List<LibraryItem> window,
  ) async {
    final database = _ref.read(queueCacheDatabaseProvider);
    if (await database.totalBytes() < limit.bytes) return true;
    if (!mounted) return false;

    await _currentService.pruneMissing();
    if (!mounted) return false;
    if (await database.totalBytes() < limit.bytes) return true;
    if (!mounted) return false;

    await _currentService.enforceLimit(
      limit.bytes,
      keepIds: {for (final song in window) song.id},
    );
    if (!mounted) return false;
    await _refreshState();
    if (!mounted) return false;
    return await database.totalBytes() < limit.bytes;
  }

  List<LibraryItem> _candidates() {
    final playback = _ref.read(playbackProvider);
    final songs = playback.songs;
    if (songs.isEmpty) return const [];
    final current = (playback.currentMediaIndex ?? 0).clamp(0, songs.length - 1);
    final window = _ref.read(forwardCacheWindowProvider).duration;

    var ahead = _lengthOf(songs[current]) - playback.position;
    if (ahead.isNegative) ahead = Duration.zero;

    final ordered = <LibraryItem>[];
    for (var i = current + 1; i < songs.length && ahead < window; i++) {
      ordered.add(songs[i]);
      ahead += _lengthOf(songs[i]);
    }
    ordered.add(songs[current]);

    final seen = <String>{};
    return [
      for (final song in ordered)
        if (seen.add(song.id)) song,
    ];
  }

  Duration _lengthOf(LibraryItem song) =>
      song.duration > Duration.zero ? song.duration : _assumedTrackLength;

  Future<void> _fill(LibraryItem song) async {
    final service = _currentService;
    _inFlight.add(song.id);

    final path = await service.cache(
      song,
      _ref.read(mediaServerClientProvider),
    );
    _inFlight.remove(song.id);
    if (!mounted) return;

    if (path == null) {
      _failedIds.add(song.id);
      return;
    }

    await _applyLimit();
    if (!mounted) return;
    await _adopt();
  }

  void _onPlayback(PlaybackState? previous, PlaybackState next) {
    final queueChanged = _queueChanged(next.songs);
    final indexChanged = previous?.currentMediaIndex != next.currentMediaIndex;
    if (!queueChanged && !indexChanged) return;

    if (queueChanged) {
      _lastQueueIds = [for (final song in next.songs) song.id];
      unawaited(_cancelStale(_lastQueueIds.toSet()));
    }
    _failedIds.clear();
    unawaited(_onQueueAdvanced(next));
  }

  bool _queueChanged(List<LibraryItem> songs) {
    if (_lastQueueIds.length != songs.length) return true;
    for (var i = 0; i < songs.length; i++) {
      if (_lastQueueIds[i] != songs[i].id) return true;
    }
    return false;
  }

  Future<void> _onQueueAdvanced(PlaybackState playback) async {
    final index = playback.currentMediaIndex;
    final current = index != null
        ? playback.songs.elementAtOrNull(index)
        : null;
    if (current != null) {
      try {
        await _ref.read(queueCacheDatabaseProvider).touch(current.id);
      } on Object catch (error) {
        debugPrint('[ForwardCache] touch failed: $error');
      }
    }
    if (!mounted) return;
    try {
      await _applyLimit();
    } on Object catch (error) {
      debugPrint('[ForwardCache] applying limit failed: $error');
    }
    if (!mounted) return;
    if (!_ref.read(forwardCacheLimitProvider).isEnabled) return;
    await _adopt();
    if (!mounted) return;
    _schedule();
  }

  Future<void> _cancelStale(Set<String> queueIds) async {
    final stale = _inFlight.where((id) => !queueIds.contains(id)).toList();
    for (final id in stale) {
      _inFlight.remove(id);
      await _service?.cancel(id);
    }
  }

  Future<void> _cancelInFlight() async {
    final pending = _inFlight.toList();
    _inFlight.clear();
    for (final id in pending) {
      await _service?.cancel(id);
    }
  }

  Future<void> cancelPending() async {
    _stopped = true;
    await _cancelInFlight();
  }

  Future<void> _onLimitChanged(ForwardCacheLimit limit) async {
    if (!limit.isEnabled) await _cancelInFlight();
    if (!mounted) return;
    try {
      await _applyLimit();
    } on Object catch (error) {
      debugPrint('[ForwardCache] applying limit failed: $error');
      return;
    }
    if (limit.isEnabled) _schedule();
  }

  Future<void> _adopt() async {
    if (!mounted) return;
    final playback = _ref.read(playbackProvider.notifier);
    if (!playback.supportsLocalFiles) return;
    final ids = _queueIds();
    if (ids.isEmpty) return;
    try {
      final paths = await _ref.read(queueCacheDatabaseProvider).pathsFor(ids);
      if (paths.isEmpty || !mounted) return;
      await playback.adoptCachedFiles(paths);
    } on Object catch (error) {
      debugPrint('[ForwardCache] adopting cached files failed: $error');
    }
  }

  Future<void> _refreshState() async {
    if (!mounted) return;
    final ids = await _ref.read(queueCacheDatabaseProvider).cachedIds();
    if (mounted) state = ids;
  }

  Set<String> _queueIds() => {
    for (final song in _ref.read(playbackProvider).songs) song.id,
  };

  @override
  void dispose() {
    _stopped = true;
    final service = _service;
    final pending = _inFlight.toList();
    _inFlight.clear();
    if (service != null) {
      for (final id in pending) {
        unawaited(service.cancel(id));
      }
    }
    super.dispose();
  }
}

final forwardCacheProvider =
    StateNotifierProvider<ForwardCacheNotifier, Set<String>>(
      ForwardCacheNotifier.new,
    );
