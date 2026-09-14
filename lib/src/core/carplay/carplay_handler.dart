import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/car/car_content.dart';
import 'package:jplayer/src/data/providers/search_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

class CarPlayHandler {
  static const _channel = MethodChannel('com.prodigytech.jellybox/carplay');
  static late CarContent _content;
  static String? _lastSetId;
  static String? _lastSongId;
  static bool? _lastPlaying;

  static void initialize(ProviderContainer ref, CarContent content) {
    if (!Platform.isIOS) return;
    _content = content;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'getHome':
          return _home();
        case 'getList':
          return _list((call.arguments as Map).cast<String, dynamic>());
        case 'getDownloads':
          return {'items': _maps(await _content.downloads())};
        case 'search':
          return _search((call.arguments as Map).cast<String, dynamic>());
        case 'getQueue':
          return _queue(ref);
        case 'playQueueItem':
          final index =
              (call.arguments as Map).cast<String, dynamic>()['index'] as int?;
          if (index != null) {
            await ref
                .read(playbackProvider.notifier)
                .skipTo(index, autoPlay: true);
          }
          return null;
        case 'play':
          final args = (call.arguments as Map).cast<String, dynamic>();
          await _content.play(args['type'] as String, args['id'] as String);
          return null;
        case 'setSort':
          final args = (call.arguments as Map).cast<String, dynamic>();
          _content.setSort(args['field'] as String?);
          return null;
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
          _notifyPlaybackState(
            setId: next.album?.id,
            songId: index != null
                ? next.songs.elementAtOrNull(index)?.id
                : null,
            playing: next.status.isPlaying,
          );
        },
      );
    _notifyContentChanged();
  }

  static void _notifyContentChanged() {
    _channel.invokeMethod('contentChanged').ignore();
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
    final recent = await _content.recentAlbums();
    return {'recent': _maps(recent), 'mixes': _maps(_content.mixes())};
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
