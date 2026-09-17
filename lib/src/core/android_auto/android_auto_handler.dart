import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/android_auto/auto_media_id.dart';
import 'package:jplayer/src/core/android_auto/cover_art_uri.dart';
import 'package:jplayer/src/core/car/car_content.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:just_audio_background/just_audio_background.dart';

class AndroidAutoHandler implements AudioBrowseDelegate {
  AndroidAutoHandler(this._ref, this._content);

  static const coverAuthority = coverArtAuthority;
  static const homeRowLimit = 8;

  static const shuffleAction = 'jellybox.shuffle';
  static const repeatAction = 'jellybox.repeat';
  static const favouriteAction = 'jellybox.favourite';

  static const _styleSupported = 'android.media.browse.CONTENT_STYLE_SUPPORTED';
  static const _searchSupported = 'android.media.browse.SEARCH_SUPPORTED';
  static const _browsableHint =
      'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT';
  static const _playableHint =
      'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT';
  static const _groupTitleHint =
      'android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT';
  static const _searchFocus = 'android.intent.extra.focus';
  static const _singleItemHint =
      'android.media.browse.CONTENT_STYLE_SINGLE_ITEM_HINT';
  static const _listStyle = 1;
  static const _gridStyle = 2;

  static const rootExtras = <String, dynamic>{
    _styleSupported: true,
    _searchSupported: true,
    _browsableHint: _listStyle,
    _playableHint: _gridStyle,
  };

  static const Map<String, int> _gridChildren = {_browsableHint: _gridStyle};
  static const Map<String, int> _listChildren = {_browsableHint: _listStyle};
  static const Map<String, int> _songChildren = {_playableHint: _listStyle};

  final ProviderContainer _ref;
  final CarContent _content;

  static void initialize(ProviderContainer ref, CarContent content) {
    if (!Platform.isAndroid) return;
    final handler = AndroidAutoHandler(ref, content);
    JustAudioBackground.browseDelegate = handler;
    JustAudioBackground.shuffleModeHandler = handler.setShuffleMode;
    JustAudioBackground.customActionHandler = handler.customAction;
    JustAudioBackground.customControls = handler.customControls;
    ref
      ..listen(
        playbackProvider.select((s) => s.shuffleEnabled),
        fireImmediately: true,
        (previous, enabled) {
          JustAudioBackground.reportShuffleMode(
            enabled
                ? AudioServiceShuffleMode.all
                : AudioServiceShuffleMode.none,
          );
          JustAudioBackground.refreshPlaybackState();
        },
      )
      ..listen(
        playbackProvider.select(_favouriteKey),
        (previous, next) => JustAudioBackground.refreshPlaybackState(),
      );
    ref
        .read(playerProvider)
        .loopModeStream
        .listen((_) => JustAudioBackground.refreshPlaybackState());
  }

  @override
  Stream<String?> get childrenChanged =>
      _content.contentChanged.map((_) => null);

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    final parent = AutoMediaId.parse(parentMediaId);
    if (parent == null) return const [];
    return switch (parent.type) {
      AutoMediaId.root => _root(),
      AutoMediaId.recent => _recent(),
      AutoMediaId.home => _home(),
      AutoMediaId.library => _library(),
      AutoMediaId.downloads => _downloads(),
      AutoMediaId.albums || AutoMediaId.playlists => _setList(parent),
      AutoMediaId.songs => _songList(parent),
      AutoMediaId.artists => _artists(parent),
      AutoMediaId.artist => _artistAlbums(parent),
      AutoMediaId.album ||
      AutoMediaId.playlist ||
      AutoMediaId.mix ||
      AutoMediaId.download => _setSongs(parent),
      _ => const [],
    };
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    final parsed = AutoMediaId.parse(mediaId);
    final id = parsed?.id;
    if (parsed == null || id == null) return null;
    final item = _content.item(id);
    return item == null ? null : _song(parsed, _content.entry(item));
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final results = await _content.search(query);
    return [
      ..._folderGroup(
        'Artists',
        AutoMediaId.artist,
        results.artists.map((e) => e.withSubtitle('Artist')),
      ),
      ..._folderGroup(
        'Albums',
        AutoMediaId.album,
        results.albums.map((e) => e.withSubtitle('Album')),
      ),
      ..._folderGroup(
        'Playlists',
        AutoMediaId.playlist,
        results.playlists.map((e) => e.withSubtitle('Playlist')),
      ),
      ..._songGroup(
        'Songs',
        CarContent.searchContext,
        results.songs.map((e) => e.withSubtitle(_songLabel(e.item))),
      ),
    ];
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    final parsed = AutoMediaId.parse(mediaId);
    if (parsed == null) return;
    if (parsed.type == AutoMediaId.resume) {
      await _ref.read(playbackProvider.notifier).resume();
      return;
    }
    final id = parsed.id;
    if (id == null) return;
    switch (parsed.type) {
      case AutoMediaId.song:
        await _content.play(parsed.type, id, songContext: parsed.context);
      case AutoMediaId.album ||
          AutoMediaId.download ||
          AutoMediaId.playlist ||
          AutoMediaId.mix ||
          AutoMediaId.artist:
        await _content.play(parsed.type, id);
    }
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final term = query.trim();
    if (term.isEmpty) return _playAnything();

    final results = await _content.search(term);
    if (results.isEmpty) return;

    final focused = switch (extras?[_searchFocus]) {
      'vnd.android.cursor.item/artist' => results.artists.firstOrNull,
      'vnd.android.cursor.item/album' => results.albums.firstOrNull,
      'vnd.android.cursor.item/playlist' => results.playlists.firstOrNull,
      _ => null,
    };
    if (focused != null) return _playSet(focused);

    final wanted = term.toLowerCase();
    bool exact(CarEntry e) => e.title.toLowerCase() == wanted;
    final exactMatch =
        results.artists.where(exact).firstOrNull ??
        results.albums.where(exact).firstOrNull ??
        results.playlists.where(exact).firstOrNull;
    if (exactMatch != null) return _playSet(exactMatch);

    final song = results.songs.firstOrNull;
    if (song != null) {
      return _content.play(
        AutoMediaId.song,
        song.id,
        songContext: CarContent.searchContext,
      );
    }

    final fallback =
        results.artists.firstOrNull ??
        results.albums.firstOrNull ??
        results.playlists.firstOrNull;
    if (fallback != null) await _playSet(fallback);
  }

  Future<void> _playAnything() async {
    if (_ref.read(playbackProvider).songs.isNotEmpty) {
      await _ref.read(playbackProvider.notifier).resume();
      return;
    }
    final mix = _content.mixes().firstOrNull;
    if (mix != null) await _content.play(AutoMediaId.mix, mix.id);
  }

  Future<void> _playSet(CarEntry entry) {
    final type = switch (entry.item.kind) {
      ItemKind.artist => AutoMediaId.artist,
      ItemKind.playlist when entry.id == likedSongsPlaylistId =>
        AutoMediaId.mix,
      ItemKind.playlist => AutoMediaId.playlist,
      _ => AutoMediaId.album,
    };
    return _content.play(type, entry.id);
  }

  Future<void> setShuffleMode(AudioServiceShuffleMode mode) => _ref
      .read(playbackProvider.notifier)
      .setShuffle(enabled: mode != AudioServiceShuffleMode.none);

  List<MediaControl> customControls() {
    final state = _ref.read(playbackProvider);
    final shuffled = state.shuffleEnabled;
    final loop = _ref.read(playerProvider).loopMode;
    final song = _currentSong(state);
    final liked = song?.userData.isFavorite ?? false;
    return [
      MediaControl.custom(
        androidIcon: shuffled
            ? 'drawable/ic_auto_shuffle_on'
            : 'drawable/ic_auto_shuffle',
        label: shuffled ? 'Shuffle on' : 'Shuffle',
        name: shuffleAction,
      ),
      MediaControl.custom(
        androidIcon: switch (loop) {
          LoopMode.off => 'drawable/ic_auto_repeat',
          LoopMode.all => 'drawable/ic_auto_repeat_on',
          LoopMode.one => 'drawable/ic_auto_repeat_one_on',
        },
        label: loop == LoopMode.off ? 'Repeat' : 'Repeat on',
        name: repeatAction,
      ),
      if (song != null)
        MediaControl.custom(
          androidIcon: liked
              ? 'drawable/ic_auto_favourite'
              : 'drawable/ic_auto_favourite_border',
          label: liked ? 'Liked' : 'Like',
          name: favouriteAction,
        ),
    ];
  }

  Future<dynamic> customAction(
    String name,
    Map<String, dynamic>? extras,
  ) async {
    switch (name) {
      case shuffleAction:
        final enabled = _ref.read(playbackProvider).shuffleEnabled;
        await _ref
            .read(playbackProvider.notifier)
            .setShuffle(enabled: !enabled);
      case repeatAction:
        final player = _ref.read(playerProvider);
        await player.setLoopMode(
          player.loopMode == LoopMode.off ? LoopMode.all : LoopMode.off,
        );
      case favouriteAction:
        await _toggleFavourite();
    }
  }

  Future<void> _toggleFavourite() async {
    final song = _currentSong(_ref.read(playbackProvider));
    if (song == null || _ref.read(isOfflineProvider)) return;
    final favourite = !song.userData.isFavorite;
    try {
      await _ref
          .read(mediaServerClientProvider)
          .setFavorite(song.id, favorite: favourite);
    } on Object {
      return;
    }
    _ref.invalidate(favouriteSongsProvider);
    _ref
        .read(playbackProvider.notifier)
        .updateSong(
          song.copyWith(
            userData: song.userData.copyWith(isFavorite: favourite),
          ),
        );
  }

  Future<List<MediaItem>> _root() async {
    if (!_content.isSignedIn) {
      return const [
        MediaItem(
          id: AutoMediaId.signIn,
          title: 'Sign in on your phone',
          artist: 'Open JellyBox to connect to your server',
        ),
      ];
    }
    return [
      _folder(AutoMediaId.home, 'Home', children: _gridChildren),
      _folder(AutoMediaId.library, 'Library', children: _listChildren),
      _folder(AutoMediaId.downloads, 'Downloads', children: _gridChildren),
    ];
  }

  bool get _offline => _ref.read(isOfflineProvider);

  static final _offlineNotice = [
    MediaItem(
      id: AutoMediaId.offline,
      title: "JellyBox can't connect to your server",
      artist: 'Downloads are still available',
      artUri: Uri.parse(
        'android.resource://com.prodigytech.jellybox/drawable/ic_auto_offline',
      ),
      extras: const {_singleItemHint: _listStyle},
    ),
  ];

  Future<List<MediaItem>> _recent() async {
    final song = _currentSong(_ref.read(playbackProvider));
    if (song == null) return const [];
    final entry = _content.entry(song);
    return [
      MediaItem(
        id: AutoMediaId.resume,
        title: entry.title,
        artist: song.artistLabel.isEmpty ? null : song.artistLabel,
        album: song.albumName,
        duration: song.duration,
        artUri: autoArtUri(entry.artUri),
      ),
    ];
  }

  Future<List<MediaItem>> _home() async {
    if (_offline) return _offlineNotice;
    final [recent, playlists] = await Future.wait([
      _content.recentAlbums(limit: homeRowLimit, shuffle: false),
      _content.playlists(limit: homeRowLimit),
    ]);
    return [
      ..._folderGroup('Recently added', AutoMediaId.album, recent),
      ..._folderGroup('Made for you', AutoMediaId.mix, _content.mixes()),
      ..._folderGroup('Playlists', AutoMediaId.playlist, playlists),
      ..._folderGroup(
        'Favourites',
        AutoMediaId.album,
        _content.favouriteAlbums(limit: homeRowLimit),
      ),
    ];
  }

  Future<List<MediaItem>> _library() async => [
    if (_offline)
      ..._offlineNotice
    else ...[
      _folder(AutoMediaId.albums, 'Albums', children: _gridChildren),
      _folder(AutoMediaId.artists, 'Artists', children: _listChildren),
      _folder(AutoMediaId.playlists, 'Playlists', children: _listChildren),
      _folder(AutoMediaId.songs, 'Songs', children: _songChildren),
    ],
  ];

  Future<List<MediaItem>> _downloads() async {
    final entries = await _content.downloads();
    return [
      for (final entry in entries)
        _setFolder(AutoMediaId(AutoMediaId.download, id: entry.id), entry),
    ];
  }

  Future<List<MediaItem>> _setList(AutoMediaId parent) async {
    final page = await _content.list(
      type: parent.type,
      startIndex: parent.start,
    );
    final type = parent.type == AutoMediaId.albums
        ? AutoMediaId.album
        : AutoMediaId.playlist;
    return [
      for (final entry in page.entries)
        _setFolder(AutoMediaId(type, id: entry.id), entry),
      if (page.hasMore) _loadMore(parent),
    ];
  }

  Future<List<MediaItem>> _songList(AutoMediaId parent) async {
    final page = await _content.list(
      type: AutoMediaId.songs,
      startIndex: parent.start,
    );
    return [
      ..._songGroup(null, CarContent.songsContext, page.entries),
      if (page.hasMore) _loadMore(parent),
    ];
  }

  Future<List<MediaItem>> _artists(AutoMediaId parent) async {
    final page = await _content.list(
      type: AutoMediaId.artists,
      startIndex: parent.start,
    );
    return [
      for (final entry in page.entries)
        _folder(
          AutoMediaId(AutoMediaId.artist, id: entry.id).encode(),
          entry.title,
          artUri: entry.artUri,
          children: _gridChildren,
        ),
      if (page.hasMore) _loadMore(parent),
    ];
  }

  Future<List<MediaItem>> _artistAlbums(AutoMediaId parent) async {
    final artistId = parent.id;
    if (artistId == null) return const [];
    final page = await _content.list(
      type: AutoMediaId.albums,
      startIndex: parent.start,
      artistId: artistId,
    );
    final artist = _content.item(artistId);
    return [
      if (parent.start == 0)
        _playAll(
          parent,
          name: artist?.name,
          artUri: _artOf(artist) ?? _firstArt(page.entries),
        ),
      for (final entry in page.entries)
        _setFolder(AutoMediaId(AutoMediaId.album, id: entry.id), entry),
      if (page.hasMore) _loadMore(parent),
    ];
  }

  Future<List<MediaItem>> _setSongs(AutoMediaId parent) async {
    final id = parent.id;
    if (id == null) return const [];
    final songs = await _content.songsOf(parent.type, id);
    if (songs.isEmpty) return const [];
    final set = _content.item(id);
    return [
      _playAll(
        parent,
        name: set?.name,
        artUri: _artOf(set) ?? _firstArt(songs),
      ),
      ..._songGroup(null, CarContent.setContext(parent.type, id), songs),
    ];
  }

  MediaItem _playAll(AutoMediaId set, {String? name, Uri? artUri}) => MediaItem(
    id: set.all.encode(),
    title: 'Play all',
    artist: name,
    artUri: autoArtUri(artUri),
  );

  MediaItem _loadMore(AutoMediaId parent) => MediaItem(
    id: parent.withStart(parent.start + CarContent.pageSize).encode(),
    title: 'Load more…',
    playable: false,
  );

  MediaItem _folder(
    String id,
    String title, {
    Uri? artUri,
    String? subtitle,
    Map<String, dynamic> children = const {},
  }) => MediaItem(
    id: id,
    title: title,
    artist: subtitle,
    artUri: autoArtUri(artUri),
    playable: false,
    extras: children.isEmpty ? null : children,
  );

  MediaItem _setFolder(AutoMediaId id, CarEntry entry, {String? group}) =>
      _folder(
        id.encode(),
        entry.title,
        subtitle: entry.subtitle.isEmpty ? null : entry.subtitle,
        artUri: entry.artUri,
        children: {..._songChildren, _groupTitleHint: ?group},
      );

  List<MediaItem> _folderGroup(
    String group,
    String type,
    Iterable<CarEntry> entries,
  ) => [
    for (final entry in entries)
      _setFolder(AutoMediaId(type, id: entry.id), entry, group: group),
  ];

  List<MediaItem> _songGroup(
    String? group,
    String context,
    Iterable<CarEntry> entries,
  ) => [
    for (final entry in entries)
      _song(
        AutoMediaId(AutoMediaId.song, id: entry.id, context: context),
        entry,
        group: group,
      ),
  ];

  MediaItem _song(AutoMediaId id, CarEntry entry, {String? group}) {
    final item = entry.item;
    return MediaItem(
      id: id.encode(),
      title: entry.title,
      artist: entry.subtitle.isEmpty ? null : entry.subtitle,
      album: item.albumName,
      duration: item.duration > Duration.zero ? item.duration : null,
      artUri: autoArtUri(entry.artUri),
      extras: group == null ? null : {_groupTitleHint: group},
    );
  }

  Uri? _artOf(LibraryItem? item) => item == null ? null : _content.artUri(item);

  static Uri? _firstArt(Iterable<CarEntry> entries) =>
      entries.map((e) => e.artUri).nonNulls.firstOrNull;

  static String _songLabel(LibraryItem song) {
    final artist = song.artistLabel;
    return artist.isEmpty ? 'Song' : 'Song • $artist';
  }

  static LibraryItem? _currentSong(PlaybackState state) {
    final index = state.currentMediaIndex;
    return index == null ? null : state.songs.elementAtOrNull(index);
  }

  static (String?, bool) _favouriteKey(PlaybackState state) {
    final song = _currentSong(state);
    return (song?.id, song?.userData.isFavorite ?? false);
  }

  static Uri? autoArtUri(Uri? uri) => androidCoverArtUri(uri);
}
