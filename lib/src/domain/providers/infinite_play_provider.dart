import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

const infinitePlayLookahead = 2;
const infinitePlayTopUp = 20;
const infinitePlayTailSeeds = 3;
const infinitePlayQueueSeeds = 2;
const infinitePlaySeedLimit = 30;

class InfinitePlayNotifier extends StateNotifier<Set<String>> {
  InfinitePlayNotifier(this._ref, {Random? random})
    : _random = random ?? Random(),
      super(const {}) {
    _ref.listen<PlaybackState>(playbackProvider, _onPlayback);
  }

  final Ref _ref;
  final Random _random;

  int? _lastIndex;
  var _lastLength = 0;
  var _lastPlaying = false;
  String? _queueKey;
  int? _exhaustedAt;
  var _extending = false;

  void _onPlayback(PlaybackState? previous, PlaybackState next) {
    final index = next.currentMediaIndex;
    final length = next.songs.length;
    final playing = next.status.isPlaying;
    if (index == _lastIndex &&
        length == _lastLength &&
        playing == _lastPlaying) {
      return;
    }
    _lastIndex = index;
    _lastLength = length;
    _lastPlaying = playing;

    final key = '${next.album?.id}/${next.sourceId}';
    final fedGone =
        state.isNotEmpty && !next.songs.any((song) => state.contains(song.id));
    if (key != _queueKey || fedGone || length == 0) {
      _queueKey = key;
      _exhaustedAt = null;
      if (state.isNotEmpty) state = const {};
    }

    if (!playing || index == null || length == 0) return;
    if (length - 1 - index > infinitePlayLookahead) return;
    unawaited(_extend(next));
  }

  Future<void> _extend(PlaybackState playback) async {
    if (_extending || _exhaustedAt == playback.songs.length) return;
    if (!_ref.read(settingProvider(AppSetting.infinitePlayback))) return;
    if (_ref.read(isOfflineProvider) || _ref.read(manualOfflineProvider)) {
      return;
    }
    if (_ref.read(playingElsewhereProvider)) return;
    final notifier = _ref.read(playbackProvider.notifier);
    final repeat = _ref
        .read(appSettingsProvider.notifier)
        .valueOf(AppSetting.repeatMode);
    if (repeat != 'off') return;
    final current = playback.songs.elementAtOrNull(
      playback.currentMediaIndex ?? -1,
    );
    if (current == null || current.isRadioStream) return;

    final seeds = pickInfinitePlaySeeds(
      playback.songs,
      set: playback.album,
      random: _random,
    );
    if (seeds.isEmpty) return;

    _extending = true;
    final anchor = playback.songs.last.id;
    final length = playback.songs.length;
    try {
      final client = _ref.read(mediaServerClientProvider);
      final mixes = await Future.wait([
        for (final seed in seeds) _mixFor(client, seed),
      ]);
      if (!mounted) return;
      final now = _ref.read(playbackProvider);
      if (now.songs.isEmpty || now.songs.last.id != anchor) return;
      final fresh = mergeInfinitePlayMixes(
        [
          for (final mix in mixes) [...mix]..shuffle(_random),
        ],
        exclude: {for (final song in now.songs) song.id, ...state},
        limit: infinitePlayTopUp,
      );
      if (fresh.isEmpty) {
        _exhaustedAt = length;
        debugPrint(
          '[InfinitePlay] nothing new to add for ${seeds.length} seeds',
        );
        return;
      }
      state = {...state, for (final song in fresh) song.id};
      debugPrint(
        '[InfinitePlay] adding ${fresh.length} songs seeded by '
        '${[for (final seed in seeds) seed.name].join(', ')}',
      );
      await notifier.addAllToQueue(fresh);
    } finally {
      _extending = false;
    }
  }

  Future<List<LibraryItem>> _mixFor(
    MediaServerClient client,
    LibraryItem seed,
  ) async {
    try {
      return await client.getInstantMix(seed.id, limit: infinitePlaySeedLimit);
    } on Object catch (error) {
      debugPrint('[InfinitePlay] mix for ${seed.name} failed: $error');
      return const [];
    }
  }
}

final infinitePlayProvider =
    StateNotifierProvider<InfinitePlayNotifier, Set<String>>(
      InfinitePlayNotifier.new,
    );

List<LibraryItem> pickInfinitePlaySeeds(
  List<LibraryItem> songs, {
  LibraryItem? set,
  Random? random,
  int tail = infinitePlayTailSeeds,
  int spread = infinitePlayQueueSeeds,
}) {
  final seeds = <LibraryItem>[];
  final seen = <String>{};
  if (set != null && _seedableSet(set)) {
    seeds.add(set);
    seen.add(set.id);
  }
  final candidates = [
    for (final song in songs)
      if (song.kind == ItemKind.song && !song.isRadioStream) song,
  ];
  var picked = 0;
  for (final song in candidates.reversed) {
    if (picked == tail) break;
    if (!seen.add(song.id)) continue;
    seeds.add(song);
    picked++;
  }
  final rest = [
    for (final song in candidates)
      if (!seen.contains(song.id)) song,
  ]..shuffle(random);
  for (final song in rest.take(spread)) {
    if (seen.add(song.id)) seeds.add(song);
  }
  return seeds;
}

bool _seedableSet(LibraryItem set) =>
    const {
      ItemKind.album,
      ItemKind.artist,
      ItemKind.playlist,
    }.contains(set.kind) &&
    !EphemeralPlaylistId.isEphemeral(set.id);

int? infinitePlayStart(List<LibraryItem> songs, Set<String> added) {
  if (added.isEmpty) return null;
  var start = -1;
  var end = -1;
  for (var i = 0; i < songs.length; i++) {
    final own = added.contains(songs[i].id);
    if (start < 0) {
      if (own) start = i;
    } else if (end < 0) {
      if (!own) end = i;
    } else if (own) {
      return null;
    }
  }
  return start < 0 ? null : start;
}

List<LibraryItem> mergeInfinitePlayMixes(
  List<List<LibraryItem>> mixes, {
  required Set<String> exclude,
  required int limit,
}) {
  final result = <LibraryItem>[];
  final seen = {...exclude};
  var longest = 0;
  for (final mix in mixes) {
    if (mix.length > longest) longest = mix.length;
  }
  for (var i = 0; i < longest; i++) {
    for (final mix in mixes) {
      if (i >= mix.length) continue;
      final song = mix[i];
      if (song.kind != ItemKind.song || song.isRadioStream) continue;
      if (!seen.add(song.id)) continue;
      result.add(song);
      if (result.length == limit) return result;
    }
  }
  return result;
}
