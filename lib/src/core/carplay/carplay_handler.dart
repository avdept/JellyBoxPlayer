import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/providers/search_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/domain/providers/todays_playlists_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:string_capitalize/string_capitalize.dart';

class CarPlayHandler {
  static const _channel = MethodChannel('com.prodigytech.jellybox/carplay');
  static final _items = <String, LibraryItem>{};
  static var _songs = <LibraryItem>[];
  static ProviderSubscription<AsyncValue<List<GeneratedPlaylist>>>? _mixesSub;
  static ProviderSubscription<AsyncValue<LibraryPage>>? _likedSongsSub;
  static String? _lastSetId;
  static String? _lastSongId;
  static bool? _lastPlaying;

  static void initialize(ProviderContainer ref) {
    if (!Platform.isIOS) return;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'getHome':
          return _home(ref);
        case 'getList':
          return _list(ref, (call.arguments as Map).cast<String, dynamic>());
        case 'getDownloads':
          return {'items': await _downloads(ref)};
        case 'search':
          return _search(ref, (call.arguments as Map).cast<String, dynamic>());
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
          await _play(ref, (call.arguments as Map).cast<String, dynamic>());
          return null;
        case 'setSort':
          _setSort(ref, (call.arguments as Map).cast<String, dynamic>());
          return null;
        default:
          throw MissingPluginException();
      }
    });

    ref
      ..listen(authProvider, (previous, next) => _notifyContentChanged())
      ..listen(
        currentLibraryProvider,
        (previous, next) => _notifyContentChanged(),
      )
      ..listen(
        carFilterProvider,
        (previous, next) => _notifyContentChanged(),
      )
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
          {..._toMap(ref, song), 'index': index},
      ],
      'currentId': currentIndex != null
          ? state.songs.elementAtOrNull(currentIndex)?.id
          : null,
    };
  }

  static Future<Map<String, dynamic>> _home(ProviderContainer ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return {'recent': <Map<String, dynamic>>[], 'mixes': _mixes(ref)};
    }

    final client = ref.read(mediaServerClientProvider);
    final libraryId = ref.read(currentLibraryProvider).valueOrNull?.id;
    final recent = await _fetch(() async {
      final resp = await client.getAlbums(
        userId: user.userId,
        libraryId: libraryId,
        limit: '20',
      );
      return resp.items;
    });

    final shuffled = [...recent]..shuffle();
    return {
      'recent': shuffled.map((e) => _toMap(ref, e)).toList(),
      'mixes': _mixes(ref),
    };
  }

  static Future<Map<String, dynamic>> _list(
    ProviderContainer ref,
    Map<String, dynamic> args,
  ) async {
    final user = ref.read(currentUserProvider);
    final filter = ref.read(carFilterProvider);
    final sort = {'field': filter.orderBy.name, 'desc': filter.desc};
    if (user == null) {
      return {'items': <Map<String, dynamic>>[], 'sort': sort};
    }

    final client = ref.read(mediaServerClientProvider);
    final libraryId = ref.read(currentLibraryProvider).valueOrNull?.id;
    final sortBy = filter.orderBy.name.capitalize();
    final sortOrder = filter.desc ? 'Descending' : 'Ascending';
    final type = args['type'] as String?;
    if (type == 'mixes') {
      return {'items': _mixes(ref), 'sort': sort, 'hasMore': false};
    }
    final startIndex = (args['startIndex'] as int?) ?? 0;
    final query = (args['query'] as String?)?.trim() ?? '';
    final artistId = args['artistId'] as String?;
    const pageSize = 100;

    final items = await _fetch(() async {
      if (query.isNotEmpty) {
        final resp = await switch (type) {
          'albums' => client.searchAlbums(
            userId: user.userId,
            libraryId: libraryId,
            searchTerm: query,
            startIndex: startIndex.toString(),
          ),
          'artists' => client.searchArtists(
            userId: user.userId,
            searchTerm: query,
            startIndex: startIndex.toString(),
          ),
          'playlists' => client.searchPlaylists(
            userId: user.userId,
            libraryId: libraryId ?? '',
            searchTerm: query,
            startIndex: startIndex.toString(),
          ),
          'songs' => client.searchSongs(
            userId: user.userId,
            libraryId: libraryId,
            searchTerm: query,
            startIndex: startIndex.toString(),
          ),
          _ => throw ArgumentError('Unknown list type: $type'),
        };
        return resp.items;
      }
      final resp = await switch (type) {
        'albums' => client.getAlbums(
          userId: user.userId,
          libraryId: artistId != null ? '' : libraryId,
          sortBy: sortBy,
          sortOrder: sortOrder,
          startIndex: startIndex.toString(),
          artistIds: artistId != null ? [artistId] : const [],
        ),
        'artists' => client.getArtists(
          userId: user.userId,
          sortBy: sortBy,
          sortOrder: sortOrder,
          startIndex: startIndex.toString(),
        ),
        'playlists' => client.getPlaylists(
          userId: user.userId,
          sortBy: sortBy,
          sortOrder: sortOrder,
          startIndex: startIndex.toString(),
        ),
        'songs' => client.getAllSongs(
          userId: user.userId,
          libraryId: libraryId,
          sortBy: filter.orderBy == EntityFilter.sortName ? 'Name' : sortBy,
          sortOrder: sortOrder,
          startIndex: startIndex.toString(),
        ),
        _ => throw ArgumentError('Unknown list type: $type'),
      };
      return resp.items;
    });

    if (type == 'songs') {
      _songs = startIndex == 0 ? items : [..._songs, ...items];
    }
    return {
      'items': items.map((e) => _toMap(ref, e)).toList(),
      'sort': sort,
      'hasMore': items.length >= pageSize,
    };
  }

  static Future<Map<String, dynamic>> _search(
    ProviderContainer ref,
    Map<String, dynamic> args,
  ) async {
    final query = (args['query'] as String?)?.trim() ?? '';
    final user = ref.read(currentUserProvider);
    const empty = <Map<String, dynamic>>[];
    if (query.isEmpty || user == null) {
      return {
        'albums': empty,
        'artists': empty,
        'playlists': empty,
        'songs': empty,
      };
    }

    final client = ref.read(mediaServerClientProvider);
    final libraryId = ref.read(currentLibraryProvider).valueOrNull?.id;
    final results = await Future.wait([
      _fetch(() async {
        final resp = await client.searchAlbums(
          userId: user.userId,
          libraryId: libraryId,
          searchTerm: query,
        );
        return resp.items;
      }),
      _fetch(() async {
        final resp = await client.searchArtists(
          userId: user.userId,
          searchTerm: query,
        );
        return resp.items;
      }),
      _fetch(() async {
        final resp = await client.searchPlaylists(
          userId: user.userId,
          libraryId: libraryId ?? '',
          searchTerm: query,
        );
        return resp.items;
      }),
      _fetch(() async {
        final resp = await client.searchSongs(
          userId: user.userId,
          libraryId: libraryId,
          searchTerm: query,
        );
        return resp.items;
      }),
    ]);

    _songs = results[3];
    return {
      'albums': results[0].map((e) => _toMap(ref, e)).toList(),
      'artists': results[1].map((e) => _toMap(ref, e)).toList(),
      'playlists': results[2].map((e) => _toMap(ref, e)).toList(),
      'songs': results[3].map((e) => _toMap(ref, e)).toList(),
    };
  }

  static void _setSort(ProviderContainer ref, Map<String, dynamic> args) {
    final field = EntityFilter.values.asNameMap()[args['field']];
    if (field == null) return;
    final filter = ref.read(carFilterProvider);
    final desc = filter.orderBy == field
        ? !filter.desc
        : field == EntityFilter.dateCreated;
    ref.read(carFilterProvider.notifier).filter(field: field, desc: desc);
  }

  static Future<List<LibraryItem>> _fetch(
    Future<List<LibraryItem>> Function() call,
  ) async {
    try {
      return await call();
    } on Object {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _downloads(
    ProviderContainer ref,
  ) async {
    try {
      final albums = await ref
          .read(downloadManagerProvider.notifier)
          .getDownloadedAlbums();
      return albums.map((e) => _toMap(ref, e.item)).toList();
    } on Object {
      return [];
    }
  }

  static List<Map<String, dynamic>> _mixes(ProviderContainer ref) {
    final entries = <Map<String, dynamic>>[];
    if (ref.read(settingProvider(AppSetting.generatedPlaylistsDisabled))) {
      _mixesSub?.close();
      _mixesSub = null;
    } else {
      _mixesSub ??= ref.listen(
        todaysPlaylistsProvider,
        (previous, next) => _notifyContentChanged(),
      );
      final playlists = ref.read(todaysPlaylistsProvider).valueOrNull;
      for (final playlist in playlists ?? const <GeneratedPlaylist>[]) {
        entries.add(_setMap(ref, playlist.item, playlist.coverSongs));
      }
    }

    final liked = _likedSongs(ref);
    if (liked != null) entries.add(liked);
    return entries;
  }

  static Map<String, dynamic>? _likedSongs(ProviderContainer ref) {
    _likedSongsSub ??= ref.listen(
      favouriteSongsProvider,
      (previous, next) => _notifyContentChanged(),
    );
    final page = ref.read(favouriteSongsProvider).valueOrNull;
    if (page == null || page.items.isEmpty) return null;
    return _setMap(ref, likedSongsPlaylist, ref.read(likedSongsCoversProvider));
  }

  static Map<String, dynamic> _setMap(
    ProviderContainer ref,
    LibraryItem item,
    List<LibraryItem> covers,
  ) {
    _items[item.id] = item;
    final imageService = ref.read(imageServiceProvider);
    var artUri = imageService.itemUri(item);
    for (final song in covers) {
      if (artUri != null) break;
      artUri = imageService.itemUri(song);
    }
    return {
      'id': item.id,
      'title': item.name,
      'subtitle': '',
      if (artUri != null) 'artworkUrl': artUri.toString(),
    };
  }

  static Map<String, dynamic> _toMap(ProviderContainer ref, LibraryItem item) {
    _items[item.id] = item;
    final artUri = ref.read(imageServiceProvider).itemUri(item);
    return {
      'id': item.id,
      'title': item.name,
      'subtitle': item.albumArtist ?? '',
      if (artUri != null) 'artworkUrl': artUri.toString(),
    };
  }

  static Future<void> _play(
    ProviderContainer ref,
    Map<String, dynamic> args,
  ) async {
    final item = _items[args['id']];
    if (item == null) return;
    final playback = ref.read(setPlaybackProvider.notifier);
    switch (args['type']) {
      case 'playlist':
        await playback.playPlaylist(item);
      case 'mix':
        if (item.id == likedSongsPlaylistId) {
          await playback.playFavouriteSongs(item);
        } else {
          await playback.playGeneratedPlaylist(item);
        }
      case 'artist':
        await playback.playArtist(item);
      case 'album':
      case 'download':
        await playback.playAlbum(item);
      case 'song':
        await _playSong(ref, item);
    }
  }

  static Future<void> _playSong(ProviderContainer ref, LibraryItem song) async {
    final syntheticAlbum = LibraryItem(
      id: song.albumId ?? song.id,
      name: song.albumName ?? '',
      kind: ItemKind.album,
      albumArtist: song.albumArtist,
      albumArtists: song.albumArtists,
      images: song.images,
    );
    final queue = _songs.isEmpty ? [song] : _songs;
    await ref.read(playbackProvider.notifier).play(song, queue, syntheticAlbum);
  }
}
