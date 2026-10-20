import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/car/car_content.dart';
import 'package:jplayer/src/data/providers/search_provider.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_toggles.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;

class CarPlayHandler {
  static const _channel = MethodChannel('com.prodigytech.jellybox/carplay');
  static late CarContent _content;
  static String? _lastSetId;
  static String? _lastSongId;
  static bool? _lastPlaying;
  static String? _lastPlayedAlbumId;
  static Timer? _homeRefresh;
  static bool _shuffle = false;
  static String _repeat = 'off';
  static bool _liked = false;

  static void initialize(ProviderContainer ref, CarContent content) {
    if (!Platform.isIOS) return;
    _content = content;

    _channel.setMethodCallHandler((call) async {
      final args = switch (call.arguments) {
        final Map<Object?, Object?> map => map.cast<String, dynamic>(),
        _ => const <String, dynamic>{},
      };
      switch (call.method) {
        case 'getHome':
          return _home();
        case 'getList':
          return _list(args);
        case 'getDownloads':
          final downloads = await _content.downloads();
          return {
            'albums': _maps(downloads.albums),
            'playlists': _maps(downloads.playlists),
          };
        case 'search':
          return _search(args);
        case 'getQueue':
          return _queue(ref);
        case 'playQueueItem':
          final index = args['index'] as int?;
          if (index != null) {
            await ref
                .read(playbackProvider.notifier)
                .skipTo(index, autoPlay: true);
          }
          return null;
        case 'play':
          await _content.play(args['type'] as String, args['id'] as String);
          return null;
        case 'setSort':
          _content.setSort(args['field'] as String?);
          return null;
        case 'toggleShuffle':
          await PlaybackToggles(ref).toggleShuffle();
          return null;
        case 'toggleRepeat':
          await PlaybackToggles(ref).toggleRepeat();
          return null;
        case 'toggleLike':
          await PlaybackToggles(ref).toggleFavourite();
          return null;
        case 'artwork':
          final url = args['url'] as String?;
          return url == null ? null : ArtworkCache.instance.pathFor(url);
        default:
          throw MissingPluginException();
      }
    });

    _content.contentChanged.listen((_) => _notifyContentChanged());
    ref
      ..listen(
        searchProvider,
        fireImmediately: true,
        (previous, next) => _channel.invokeMethod('searchChanged', {
          'query': next ?? '',
        }).ignore(),
      )
      ..listen(
        playbackProvider,
        fireImmediately: true,
        (previous, next) {
          final index = next.currentMediaIndex;
          final song = index != null
              ? next.songs.elementAtOrNull(index)
              : null;
          _notifyPlaybackState(
            setId: next.album?.id,
            songId: song?.id,
            playing: next.status.isPlaying,
          );
          if (next.status.isPlaying) _notifyAlbumPlayed(song?.albumId);
          final liked = song?.userData.isFavorite ?? false;
          if (next.shuffleEnabled != _shuffle || liked != _liked) {
            _shuffle = next.shuffleEnabled;
            _liked = liked;
            _notifyModes();
          }
        },
      );
    ref.read(playerProvider).loopModeStream.listen((mode) {
      final value = switch (mode) {
        LoopMode.off => 'off',
        LoopMode.all => 'all',
        LoopMode.one => 'one',
      };
      if (value == _repeat) return;
      _repeat = value;
      _notifyModes();
    });
    _notifyContentChanged();
  }

  static void _notifyContentChanged() {
    _channel.invokeMethod('contentChanged').ignore();
  }

  static void _notifyModes() {
    _channel.invokeMethod('modesChanged', {
      'shuffle': _shuffle,
      'repeat': _repeat,
      'liked': _liked,
    }).ignore();
  }

  static void _notifyAlbumPlayed(String? albumId) {
    if (albumId == null || albumId == _lastPlayedAlbumId) return;
    _lastPlayedAlbumId = albumId;
    _homeRefresh?.cancel();
    _homeRefresh = Timer(const Duration(seconds: 5), () {
      _channel.invokeMethod('homeChanged').ignore();
    });
  }

  static void _notifyPlaybackState({
    required String? setId,
    required String? songId,
    required bool playing,
  }) {
    if (setId == _lastSetId &&
        songId == _lastSongId &&
        playing == _lastPlaying) {
      return;
    }
    _lastSetId = setId;
    _lastSongId = songId;
    _lastPlaying = playing;
    _channel.invokeMethod('playbackState', {
      'playing': playing,
      'setId': ?setId,
      'songId': ?songId,
    }).ignore();
  }

  static Map<String, dynamic> _queue(ProviderContainer ref) {
    final state = ref.read(playbackProvider);
    final currentIndex = state.currentMediaIndex;
    return {
      'items': [
        for (final (index, song) in state.songs.indexed)
          {..._map(_content.entry(song)), 'index': index},
      ],
      'currentId': currentIndex != null
          ? state.songs.elementAtOrNull(currentIndex)?.id
          : null,
    };
  }

  static Future<Map<String, dynamic>> _home() async {
    final (recent, played) = await (
      _content.recentAlbums(),
      _content.recentlyPlayedAlbums(),
    ).wait;
    return {
      'recent': _maps(recent),
      'played': _maps(played),
      'mixes': _maps(_content.mixes()),
    };
  }

  static Future<Map<String, dynamic>> _list(Map<String, dynamic> args) async {
    final page = await _content.list(
      type: args['type'] as String? ?? '',
      startIndex: (args['startIndex'] as int?) ?? 0,
      query: args['query'] as String? ?? '',
      artistId: args['artistId'] as String?,
    );
    return {
      'items': _maps(page.entries),
      'sort': _sortMap(page.sort),
      'hasMore': page.hasMore,
    };
  }

  static Future<Map<String, dynamic>> _search(
    Map<String, dynamic> args,
  ) async {
    final results = await _content.search(args['query'] as String? ?? '');
    return {
      'albums': _maps(results.albums),
      'artists': _maps(results.artists),
      'playlists': _maps(results.playlists),
      'songs': _maps(results.songs),
    };
  }

  static Map<String, dynamic> _sortMap(Filter sort) => {
    'field': sort.orderBy.name,
    'desc': sort.desc,
  };

  static List<Map<String, dynamic>> _maps(List<CarEntry> entries) =>
      entries.map(_map).toList();

  static Map<String, dynamic> _map(CarEntry entry) => {
    'id': entry.id,
    'title': entry.title,
    'subtitle': entry.subtitle,
    if (entry.artUri != null) 'artworkUrl': entry.artUri.toString(),
  };
}
