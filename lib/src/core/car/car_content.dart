import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/artist_scope_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/downloaded_albums_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/items_filter_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/domain/providers/todays_playlists_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class CarEntry {
  const CarEntry({
    required this.item,
    required this.title,
    required this.subtitle,
    this.artUri,
  });

  final LibraryItem item;
  final String title;
  final String subtitle;
  final Uri? artUri;

  String get id => item.id;

  CarEntry withSubtitle(String value) =>
      CarEntry(item: item, title: title, subtitle: value, artUri: artUri);
}

class CarPage {
  const CarPage({
    required this.entries,
    required this.sort,
    this.hasMore = false,
  });

  final List<CarEntry> entries;
  final Filter sort;
  final bool hasMore;
}

class CarSearchResults {
  const CarSearchResults({
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    this.songs = const [],
  });

  final List<CarEntry> albums;
  final List<CarEntry> artists;
  final List<CarEntry> playlists;
  final List<CarEntry> songs;

  bool get isEmpty =>
      albums.isEmpty && artists.isEmpty && playlists.isEmpty && songs.isEmpty;
}

class CarContent {
  CarContent(this._ref) {
    _ref
      ..listen(authProvider, (previous, next) {
        _items.clear();
        _songLists.clear();
        _lastSongsKey = null;
        _notifyChanged();
      })
      ..listen(currentLibraryProvider, (previous, next) => _notifyChanged())
      ..listen(carFilterProvider, (previous, next) => _notifyChanged())
      ..listen(isOfflineProvider, (previous, next) => _notifyChanged())
      ..listen(downloadedAlbumsProvider, (previous, next) => _notifyChanged());
  }

  static const recentAlbumsLimit = 20;
  static const pageSize = 100;
  static const songsContext = 'songs';
  static const searchContext = 'search';

  final ProviderContainer _ref;
  final _items = <String, LibraryItem>{};
  final _songLists = <String, List<LibraryItem>>{};
  final _changes = StreamController<void>.broadcast();
  String? _lastSongsKey;
  ProviderSubscription<AsyncValue<List<GeneratedPlaylist>>>? _mixesSub;
  ProviderSubscription<AsyncValue<LibraryPage>>? _likedSongsSub;
  ProviderSubscription<AsyncValue<List<LibraryItem>>>? _favouriteAlbumsSub;

  Stream<void> get contentChanged => _changes.stream;

  bool get isSignedIn => _ref.read(currentUserProvider) != null;

  Filter get sort => _ref.read(carFilterProvider);

  LibraryItem? item(String id) => _items[id];

  List<LibraryItem> songsIn(String context) => _songLists[context] ?? const [];

  void _notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<List<CarEntry>> recentAlbums({
    int limit = recentAlbumsLimit,
    bool shuffle = true,
  }) async {
    if (!isSignedIn) return const [];
    final client = _ref.read(mediaServerClientProvider);
    final libraryId = _ref.read(currentLibraryProvider).valueOrNull?.id;
    final recent = await _fetch(() async {
      final resp = await client.getAlbums(
        LibraryQuery(
          libraryId: libraryId,
          sort: ItemSort.dateCreated,
          direction: SortDirection.descending,
          limit: limit,
        ),
      );
      return resp.items;
    });
    final ordered = shuffle ? ([...recent]..shuffle()) : recent;
    return ordered.take(limit).map(entry).toList();
  }

  Future<List<CarEntry>> playlists({required int limit}) async {
    if (!isSignedIn) return const [];
    final client = _ref.read(mediaServerClientProvider);
    final items = await _fetch(() async {
      final resp = await client.getPlaylists(
        LibraryQuery(
          sort: ItemSort.dateLastContentAdded,
          direction: SortDirection.descending,
          limit: limit,
        ),
      );
      return resp.items;
    });
    return items.take(limit).map(entry).toList();
  }

  List<CarEntry> favouriteAlbums({required int limit}) {
    _favouriteAlbumsSub ??= _ref.listen(
      favouriteAlbumsProvider,
      (previous, next) => _notifyChanged(),
    );
    final albums = _ref.read(favouriteAlbumsProvider).valueOrNull;
    if (albums == null) return const [];
    return albums.take(limit).map(entry).toList();
  }

  List<CarEntry> mixes() {
    final entries = <CarEntry>[];
    if (_ref.read(settingProvider(AppSetting.generatedPlaylistsDisabled))) {
      _mixesSub?.close();
      _mixesSub = null;
    } else {
      _mixesSub ??= _ref.listen(
        todaysPlaylistsProvider,
        (previous, next) => _notifyChanged(),
      );
      final playlists = _ref.read(todaysPlaylistsProvider).valueOrNull;
      for (final playlist in playlists ?? const <GeneratedPlaylist>[]) {
        entries.add(_setEntry(playlist.item, playlist.coverSongs));
      }
    }

    final liked = _likedSongs();
    if (liked != null) entries.add(liked);
    return entries;
  }

  CarEntry? _likedSongs() {
    _likedSongsSub ??= _ref.listen(
      favouriteSongsProvider,
      (previous, next) => _notifyChanged(),
    );
    final page = _ref.read(favouriteSongsProvider).valueOrNull;
    if (page == null || page.items.isEmpty) return null;
    return _setEntry(likedSongsPlaylist, _ref.read(likedSongsCoversProvider));
  }

  Future<CarPage> list({
    required String type,
    int startIndex = 0,
    String query = '',
    String? artistId,
  }) async {
    final filter = sort;
    if (!isSignedIn) return CarPage(entries: const [], sort: filter);
    if (type == 'mixes') return CarPage(entries: mixes(), sort: filter);

    final client = _ref.read(mediaServerClientProvider);
    final libraryId = _ref.read(currentLibraryProvider).valueOrNull?.id;
    final itemSort = filter.orderBy.itemSort;
    final direction = sortDirectionOf(descending: filter.desc);
    final term = query.trim();

    var items = await _fetch(() async {
      if (term.isNotEmpty) {
        final resp = await switch (type) {
          'albums' => client.searchAlbums(
            SearchQuery(
              term: term,
              libraryId: libraryId,
              startIndex: startIndex,
            ),
          ),
          'artists' => client.searchArtists(
            SearchQuery(term: term, startIndex: startIndex),
          ),
          'playlists' => client.searchPlaylists(
            SearchQuery(
              term: term,
              libraryId: libraryId,
              startIndex: startIndex,
            ),
          ),
          'songs' => client.searchSongs(
            SearchQuery(
              term: term,
              libraryId: libraryId,
              startIndex: startIndex,
            ),
          ),
          _ => throw ArgumentError('Unknown list type: $type'),
        };
        return resp.items;
      }
      final resp = await switch (type) {
        'albums' => client.getAlbums(
          LibraryQuery(
            libraryId: artistId != null ? null : libraryId,
            sort: itemSort,
            direction: direction,
            startIndex: startIndex,
            artistIds: artistId != null ? [artistId] : const [],
          ),
        ),
        'artists' => client.getArtists(
          LibraryQuery(
            sort: itemSort,
            direction: direction,
            startIndex: startIndex,
            artistScope: _ref.read(effectiveArtistScopeProvider),
          ),
        ),
        'playlists' => client.getPlaylists(
          LibraryQuery(
            sort: itemSort,
            direction: direction,
            startIndex: startIndex,
          ),
        ),
        'songs' => client.getAllSongs(
          LibraryQuery(
            libraryId: libraryId,
            sort: itemSort,
            direction: direction,
            startIndex: startIndex,
          ),
        ),
        _ => throw ArgumentError('Unknown list type: $type'),
      };
      return resp.items;
    });

    if (type == 'albums' && artistId != null && startIndex == 0) {
      final appearsOn = await _fetch(() async {
        final resp = await client.getAlbums(
          LibraryQuery(
            sort: itemSort,
            direction: direction,
            appearsOnArtistId: artistId,
          ),
        );
        return resp.items;
      });
      final known = items.map((e) => e.id).toSet();
      items = [...items, ...appearsOn.where((e) => known.add(e.id))];
    }

    if (type == 'songs') {
      final key = term.isNotEmpty ? searchContext : songsContext;
      final previous = _songLists[key] ?? const <LibraryItem>[];
      _songLists[key] = startIndex == 0 ? items : [...previous, ...items];
      _lastSongsKey = key;
    }
    return CarPage(
      entries: items.map(entry).toList(),
      sort: filter,
      hasMore: items.length >= pageSize,
    );
  }

  Future<CarSearchResults> search(String query) async {
    final term = query.trim();
    if (term.isEmpty || !isSignedIn) return const CarSearchResults();

    final client = _ref.read(mediaServerClientProvider);
    final libraryId = _ref.read(currentLibraryProvider).valueOrNull?.id;
    final results = await Future.wait([
      _fetch(() async {
        final resp = await client.searchAlbums(
          SearchQuery(term: term, libraryId: libraryId),
        );
        return resp.items;
      }),
      _fetch(() async {
        final resp = await client.searchArtists(
          SearchQuery(
            term: term,
            artistScope: _ref.read(effectiveArtistScopeProvider),
          ),
        );
        return resp.items;
      }),
      _fetch(() async {
        final resp = await client.searchPlaylists(
          SearchQuery(term: term, libraryId: libraryId),
        );
        return resp.items;
      }),
      _fetch(() async {
        final resp = await client.searchSongs(
          SearchQuery(term: term, libraryId: libraryId),
        );
        return resp.items;
      }),
    ]);

    _songLists[searchContext] = results[3];
    _lastSongsKey = searchContext;
    return CarSearchResults(
      albums: results[0].map(entry).toList(),
      artists: results[1].map(entry).toList(),
      playlists: results[2].map(entry).toList(),
      songs: results[3].map(entry).toList(),
    );
  }

  Future<List<CarEntry>> downloads() async {
    try {
      final albums = await _ref
          .read(downloadManagerProvider.notifier)
          .getDownloadedAlbums();
      return albums.map((e) => entry(e.item)).toList();
    } on Object {
      return const [];
    }
  }

  void setSort(String? field) {
    final entity = EntityFilter.values.asNameMap()[field];
    if (entity == null) return;
    final filter = sort;
    final desc = filter.orderBy == entity
        ? !filter.desc
        : entity == EntityFilter.dateCreated;
    _ref.read(carFilterProvider.notifier).filter(field: entity, desc: desc);
  }

  Future<void> play(String type, String id, {String? songContext}) async {
    final item = await _resolve(type, id);
    if (item == null) return;
    final playback = _ref.read(setPlaybackProvider.notifier);
    switch (type) {
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
        await playSong(item, context: songContext);
    }
  }

  static String setContext(String type, String id) => '$type:$id';

  Future<List<CarEntry>> songsOf(String type, String id) async {
    final set = await _resolve(type, id);
    if (set == null) return const [];
    final playback = _ref.read(setPlaybackProvider.notifier);
    final songs = await _fetch(
      () => switch (type) {
        'album' || 'download' => playback.albumSongs(id),
        'playlist' => playback.playlistSongs(id),
        'mix' when id == likedSongsPlaylistId => playback.favouriteSongs(),
        'mix' => playback.generatedPlaylistSongs(id),
        _ => Future.value(const <LibraryItem>[]),
      },
    );
    _songLists[setContext(type, id)] = songs;
    return songs.map(entry).toList();
  }

  Future<void> playSong(LibraryItem song, {String? context}) async {
    final key = context ?? _lastSongsKey;
    final songs = key == null ? const <LibraryItem>[] : songsIn(key);
    final queue = songs.any((s) => s.id == song.id) ? songs : [song];
    final set = key == null ? null : _setFor(key);
    final album =
        set ??
        LibraryItem(
          id: song.albumId ?? song.id,
          name: song.albumName ?? '',
          kind: ItemKind.album,
          albumArtist: song.albumArtist,
          albumArtists: song.albumArtists,
          images: song.images,
        );
    await _ref.read(playbackProvider.notifier).play(song, queue, album);
  }

  LibraryItem? _setFor(String context) {
    final separator = context.indexOf(':');
    if (separator < 0) return null;
    return _items[context.substring(separator + 1)];
  }

  Future<LibraryItem?> _resolve(String type, String id) async {
    final cached = _items[id];
    if (cached != null) return cached;
    if (type == 'mix') {
      if (id == likedSongsPlaylistId) return likedSongsPlaylist;
      final playlists = _ref.read(todaysPlaylistsProvider).valueOrNull;
      return playlists?.where((p) => p.item.id == id).firstOrNull?.item;
    }
    if (type == 'download') {
      final albums = await downloads();
      return albums.where((e) => e.id == id).firstOrNull?.item;
    }
    if (!isSignedIn) return null;
    final kind = switch (type) {
      'album' => ItemKind.album,
      'artist' => ItemKind.artist,
      'playlist' => ItemKind.playlist,
      'song' => ItemKind.song,
      _ => null,
    };
    if (kind == null) return null;
    try {
      final item = await _ref
          .read(mediaServerClientProvider)
          .getItem(id, kind: kind);
      _items[item.id] = item;
      return item;
    } on Object {
      return null;
    }
  }

  Uri? artUri(LibraryItem item) =>
      _ref.read(imageServiceProvider).itemUri(item);

  CarEntry entry(LibraryItem item) {
    _items[item.id] = item;
    return CarEntry(
      item: item,
      title: item.name,
      subtitle: item.albumArtist ?? '',
      artUri: artUri(item),
    );
  }

  CarEntry _setEntry(LibraryItem item, List<LibraryItem> covers) {
    _items[item.id] = item;
    var uri = artUri(item);
    for (final song in covers) {
      if (uri != null) break;
      uri = artUri(song);
    }
    return CarEntry(item: item, title: item.name, subtitle: '', artUri: uri);
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
}
