import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/android_auto/auto_media_id.dart';
import 'package:jplayer/src/core/car/car_content.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AndroidAutoHandler implements AudioBrowseDelegate {
  AndroidAutoHandler(this._ref, this._content);

  static const coverAuthority = 'com.prodigytech.jellybox.covers';

  static const _styleSupported = 'android.media.browse.CONTENT_STYLE_SUPPORTED';
  static const _browsableHint =
      'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT';
  static const _playableHint =
      'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT';
  static const _groupTitleHint =
      'android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT';
  static const _searchFocus = 'android.intent.extra.focus';
  static const _listStyle = 1;
  static const _gridStyle = 2;

  static const rootExtras = <String, dynamic>{
    _styleSupported: true,
    _browsableHint: _listStyle,
    _playableHint: _gridStyle,
  };

  static AndroidAutoHandler? _instance;

  static void initialize(ProviderContainer ref, CarContent content) {
    if (!Platform.isAndroid) return;
    _instance = AndroidAutoHandler(ref, content);
    JustAudioBackground.browseDelegate = _instance;
  }

  final ProviderContainer _ref;
  final CarContent _content;

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
      AutoMediaId.albums ||
      AutoMediaId.playlists ||
      AutoMediaId.songs => _playableList(parent),
      AutoMediaId.artists => _artists(parent),
      AutoMediaId.artist => _artistAlbums(parent),
      _ => const [],
    };
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    final parsed = AutoMediaId.parse(mediaId);
    final id = parsed?.id;
    if (parsed == null || id == null) return null;
    final item = _content.item(id);
    if (item == null) return null;
    return _playable(parsed, _content.entry(item));
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final results = await _content.search(query);
    return [
      ..._grouped('Artists', results.artists, _entryId(AutoMediaId.artist)),
      ..._grouped('Albums', results.albums, _entryId(AutoMediaId.album)),
      ..._grouped(
        'Playlists',
        results.playlists,
        _entryId(AutoMediaId.playlist),
      ),
      ..._grouped(
        'Songs',
        results.songs,
        _entryId(AutoMediaId.song, context: CarContent.searchContext),
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
    final id = parsed.id;
    switch (parsed.type) {
      case AutoMediaId.resume:
        await _ref.read(playbackProvider.notifier).resume();
      case AutoMediaId.artistAll when id != null:
        await _content.play(AutoMediaId.artist, id);
      case AutoMediaId.song when id != null:
        await _content.play(parsed.type, id, songContext: parsed.context);
      case AutoMediaId.album ||
              AutoMediaId.download ||
              AutoMediaId.playlist ||
              AutoMediaId.mix ||
              AutoMediaId.artist
          when id != null:
        await _content.play(parsed.type, id);
    }
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final term = query.trim();
    if (term.isEmpty) {
      if (_ref.read(playbackProvider).songs.isNotEmpty) {
        await _ref.read(playbackProvider.notifier).resume();
        return;
      }
      final mix = _content.mixes().firstOrNull;
      if (mix != null) await _content.play(AutoMediaId.mix, mix.id);
      return;
    }

    final results = await _content.search(term);
    if (results.isEmpty) return;

    final focus = extras?[_searchFocus] as String?;
    final focused = switch (focus) {
      'vnd.android.cursor.item/artist' => (
        AutoMediaId.artist,
        results.artists.firstOrNull,
      ),
      'vnd.android.cursor.item/album' => (
        AutoMediaId.album,
        results.albums.firstOrNull,
      ),
      'vnd.android.cursor.item/playlist' => (
        AutoMediaId.playlist,
        results.playlists.firstOrNull,
      ),
      _ => null,
    };
    if (focused != null && focused.$2 != null) {
      await _content.play(focused.$1, focused.$2!.id);
      return;
    }

    final lower = term.toLowerCase();
    bool exact(CarEntry e) => e.title.toLowerCase() == lower;
    final exactArtist = results.artists.where(exact).firstOrNull;
    if (exactArtist != null) {
      await _content.play(AutoMediaId.artist, exactArtist.id);
      return;
    }
    final exactAlbum = results.albums.where(exact).firstOrNull;
    if (exactAlbum != null) {
      await _content.play(AutoMediaId.album, exactAlbum.id);
      return;
    }
    final exactPlaylist = results.playlists.where(exact).firstOrNull;
    if (exactPlaylist != null) {
      await _content.play(AutoMediaId.playlist, exactPlaylist.id);
      return;
    }
    final song = results.songs.firstOrNull;
    if (song != null) {
      await _content.play(
        AutoMediaId.song,
        song.id,
        songContext: CarContent.searchContext,
      );
      return;
    }
    final fallback =
        results.artists.firstOrNull ??
        results.albums.firstOrNull ??
        results.playlists.firstOrNull;
    if (fallback == null) return;
    final type = switch (fallback.item.kind) {
      ItemKind.artist => AutoMediaId.artist,
      ItemKind.playlist => AutoMediaId.playlist,
      _ => AutoMediaId.album,
    };
    await _content.play(type, fallback.id);
  }

  Future<List<MediaItem>> _root() async {
    if (!_content.isSignedIn) {
      return [
        const MediaItem(
          id: AutoMediaId.signIn,
          title: 'Sign in on your phone',
          artist: 'Open JellyBox to connect to your server',
        ),
      ];
    }
    final downloads = _folder(
      AutoMediaId.downloads,
      'Downloads',
      childStyle: {_playableHint: _gridStyle},
    );
    if (_ref.read(isOfflineProvider)) return [downloads];
    return [
      _folder(
        AutoMediaId.home,
        'Home',
        childStyle: {_playableHint: _gridStyle},
      ),
      _folder(
        AutoMediaId.library,
        'Library',
        childStyle: {_browsableHint: _listStyle},
      ),
      downloads,
    ];
  }

  Future<List<MediaItem>> _recent() async {
    final state = _ref.read(playbackProvider);
    final index = state.currentMediaIndex;
    final song = index == null ? null : state.songs.elementAtOrNull(index);
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
    final mixes = _content.mixes();
    final recent = await _content.recentAlbums();
    return [
      ..._grouped('Made for you', mixes, _entryId(AutoMediaId.mix)),
      ..._grouped('Recently added', recent, _entryId(AutoMediaId.album)),
    ];
  }

  Future<List<MediaItem>> _library() async => [
    _folder(
      AutoMediaId.albums,
      'Albums',
      childStyle: {_playableHint: _gridStyle},
    ),
    _folder(
      AutoMediaId.artists,
      'Artists',
      childStyle: {_browsableHint: _listStyle},
    ),
    _folder(
      AutoMediaId.playlists,
      'Playlists',
      childStyle: {_playableHint: _listStyle},
    ),
    _folder(
      AutoMediaId.songs,
      'Songs',
      childStyle: {_playableHint: _listStyle},
    ),
  ];

  Future<List<MediaItem>> _downloads() async {
    final entries = await _content.downloads();
    return entries
        .map((e) => _playable(AutoMediaId(AutoMediaId.download, id: e.id), e))
        .toList();
  }

  Future<List<MediaItem>> _playableList(AutoMediaId parent) async {
    final page = await _content.list(
      type: parent.type,
      startIndex: parent.start,
    );
    final (type, context) = switch (parent.type) {
      AutoMediaId.albums => (AutoMediaId.album, null),
      AutoMediaId.playlists => (AutoMediaId.playlist, null),
      _ => (AutoMediaId.song, CarContent.songsContext),
    };
    return [
      for (final entry in page.entries)
        _playable(AutoMediaId(type, id: entry.id, context: context), entry),
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
          childStyle: {_playableHint: _gridStyle},
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
        MediaItem(
          id: AutoMediaId(AutoMediaId.artistAll, id: artistId).encode(),
          title: 'Play all',
          artist: artist?.name,
          artUri: artist == null ? null : autoArtUri(_content.artUri(artist)),
        ),
      for (final entry in page.entries)
        _playable(AutoMediaId(AutoMediaId.album, id: entry.id), entry),
      if (page.hasMore) _loadMore(parent),
    ];
  }

  MediaItem _loadMore(AutoMediaId parent) => MediaItem(
    id: parent.withStart(parent.start + CarContent.pageSize).encode(),
    title: 'Load more…',
    playable: false,
    extras: const {_playableHint: _gridStyle},
  );

  MediaItem _folder(
    String id,
    String title, {
    Uri? artUri,
    Map<String, dynamic> childStyle = const {},
  }) => MediaItem(
    id: id,
    title: title,
    artUri: autoArtUri(artUri),
    playable: false,
    extras: childStyle.isEmpty ? null : childStyle,
  );

  AutoMediaId Function(CarEntry) _entryId(String type, {String? context}) =>
      (entry) => AutoMediaId(type, id: entry.id, context: context);

  List<MediaItem> _grouped(
    String group,
    List<CarEntry> entries,
    AutoMediaId Function(CarEntry) idOf,
  ) => [
    for (final entry in entries)
      _playable(idOf(entry), entry, extras: {_groupTitleHint: group}),
  ];

  MediaItem _playable(
    AutoMediaId id,
    CarEntry entry, {
    Map<String, dynamic>? extras,
  }) {
    final item = entry.item;
    final isSong = item.kind == ItemKind.song;
    return MediaItem(
      id: id.encode(),
      title: entry.title,
      artist: entry.subtitle.isEmpty ? null : entry.subtitle,
      album: isSong ? item.albumName : null,
      duration: isSong && item.duration > Duration.zero ? item.duration : null,
      artUri: autoArtUri(entry.artUri),
      extras: extras,
    );
  }

  static Uri? autoArtUri(Uri? uri) {
    if (uri == null || !uri.isScheme('file')) return uri;
    final segments = uri.pathSegments;
    if (segments.length < 2) return null;
    final albumId = segments[segments.length - 2];
    return Uri(
      scheme: 'content',
      host: coverAuthority,
      pathSegments: [albumId],
    );
  }
}
