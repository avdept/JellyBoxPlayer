import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_screen_widgets/home_screen_widgets.dart';
import 'package:jplayer/src/core/home_widget/widget_artwork.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/now_playing_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:just_audio_background/just_audio_background.dart'
    show MediaItem;
import 'package:path/path.dart' as p;

abstract interface class WidgetHost {
  Future<String?> directory();

  Future<void> reload();

  Future<List<int>?> artwork({
    required String source,
    required String target,
    required int size,
  });
}

class PluginWidgetHost implements WidgetHost {
  const PluginWidgetHost();

  static const appGroup = 'group.com.prodigytech.jellybox';
  static const androidProvider = 'com.prodigytech.jellybox.NowPlayingWidget';
  static const iosKind = 'NowPlayingWidget';

  static const _plugin = HomeScreenWidgets(appGroup: appGroup);

  @override
  Future<String?> directory() => _plugin.directory();

  @override
  Future<void> reload() =>
      _plugin.reload(androidProvider: androidProvider, iosKind: iosKind);

  @override
  Future<List<int>?> artwork({
    required String source,
    required String target,
    required int size,
  }) => _plugin.artwork(source: source, target: target, size: size);
}

typedef ArtworkSourceResolver = Future<String?> Function(Uri? uri);

typedef RecentAlbumsLoader = Future<List<LibraryItem>> Function();

typedef AlbumArtResolver = Uri? Function(LibraryItem album);

typedef _Recent = ({String id, String title, String? cover});

class NowPlayingWidgetSync {
  NowPlayingWidgetSync({
    WidgetHost host = const PluginWidgetHost(),
    ArtworkSourceResolver artworkSource = widgetArtworkSource,
    RecentAlbumsLoader? recentAlbums,
    AlbumArtResolver? albumArt,
    Duration recentDelay = const Duration(seconds: 15),
  }) : _host = host,
       _artworkSource = artworkSource,
       _recentAlbums = recentAlbums,
       _albumArt = albumArt,
       _recentDelay = recentDelay;

  static const snapshotFile = 'now_playing.json';
  static const coverFile = 'now_playing_cover.png';
  static const recentCount = 4;

  final WidgetHost _host;
  final ArtworkSourceResolver _artworkSource;
  final RecentAlbumsLoader? _recentAlbums;
  final AlbumArtResolver? _albumArt;
  final Duration _recentDelay;

  Future<Directory?>? _directory;
  Future<void>? _draining;
  var _running = false;
  var _dirty = false;
  String? _published;
  var _signedOut = false;
  String? _coverId;
  WidgetArtwork? _cover;
  List<_Recent> _recent = const [];
  Timer? _recentTimer;
  Future<void>? _recentLoad;
  String? _playingSet;

  MediaItem? _item;
  var _playing = false;
  var _liked = false;
  var _shuffle = false;
  LoopMode _repeat = LoopMode.off;

  static void initialize(ProviderContainer ref) {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!Platform.isIOS) {
      NowPlayingWidgetSync().attach(ref);
      return;
    }
    NowPlayingWidgetSync(
      recentAlbums: () => _loadRecentAlbums(ref),
      albumArt: (album) => ref.read(imageServiceProvider).itemUri(album),
    ).attach(ref);
  }

  static Future<List<LibraryItem>> _loadRecentAlbums(
    ProviderContainer ref,
  ) async {
    final library = ref.listen(currentLibraryProvider, (_, _) {});
    try {
      final current = await ref
          .read(currentLibraryProvider.future)
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
      return await ref
          .read(mediaServerClientProvider)
          .getRecentlyPlayedAlbums(libraryId: current?.id, limit: recentCount);
    } finally {
      library.close();
    }
  }

  void attach(
    ProviderContainer ref, {
    Stream<LoopMode>? loopModes,
    ProviderListenable<AsyncValue<bool?>>? signedIn,
  }) {
    ref.listen(signedIn ?? authProvider, fireImmediately: true, (
      previous,
      next,
    ) {
      if (next is! AsyncData<bool?>) return;
      _signedOut = next.value == false;
      if (_signedOut) {
        _recentTimer?.cancel();
        _recent = const [];
      } else if (next.value == true) {
        _loadRecent();
      }
      _schedule();
    });
    ref.listen(
      playbackProvider.select(
        (state) => (
          state.currentMediaIndex == null
              ? null
              : state.songs.elementAtOrNull(state.currentMediaIndex!),
          state.album,
          state.status.isPlaying || state.status == PlaybackStatus.buffering,
          state.shuffleEnabled,
        ),
      ),
      fireImmediately: true,
      (previous, next) {
        final (song, album, playing, shuffle) = next;
        _item = song == null
            ? null
            : mediaItemFor(
                song,
                album: album,
                images: ref.read(imageServiceProvider),
              );
        _playing = playing;
        _liked = song?.userData.isFavorite ?? false;
        _shuffle = shuffle;
        _onPlayingSet(album?.id);
        _schedule();
      },
    );
    (loopModes ?? ref.read(playerProvider).loopModeStream).listen((mode) {
      _repeat = mode;
      _schedule();
    });
  }

  @visibleForTesting
  Future<void> get idle async {
    while (_running || (_recentTimer?.isActive ?? false)) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    await _recentLoad;
    await _draining;
  }

  void _loadRecent() => _recentLoad = _refreshRecent();

  void _onPlayingSet(String? id) {
    if (_recentAlbums == null || id == null || id == _playingSet) return;
    final first = _playingSet == null;
    _playingSet = id;
    if (first) return;
    _recentTimer?.cancel();
    _recentTimer = Timer(_recentDelay, _loadRecent);
  }

  Future<void> _refreshRecent() async {
    final load = _recentAlbums;
    if (load == null || _signedOut) return;
    final directory = await (_directory ??= _resolveDirectory());
    if (directory == null) return;

    final List<LibraryItem> albums;
    try {
      albums = (await load()).take(recentCount).toList();
    } on Object catch (error) {
      debugPrint('[HomeWidget] recent albums failed: $error');
      return;
    }
    final ids = [for (final album in albums) album.id];
    if (listEquals(ids, [for (final recent in _recent) recent.id])) return;

    final recent = <_Recent>[];
    for (final (index, album) in albums.indexed) {
      final file = File(p.join(directory.path, 'recent_$index.png'));
      final written = await _writeArtwork(
        _albumArt?.call(album),
        file,
        widgetThumbnailSize,
      );
      recent.add((
        id: album.id,
        title: album.name,
        cover: written == null ? null : file.path,
      ));
    }
    if (_signedOut) return;
    _recent = recent;
    _schedule();
  }

  void _schedule() {
    _dirty = true;
    if (!_running) _draining = _drain();
  }

  Future<void> _drain() async {
    _running = true;
    while (_dirty) {
      _dirty = false;
      try {
        await _apply(_item);
      } on Object catch (error) {
        debugPrint('[HomeWidget] update failed: $error');
      }
    }
    _running = false;
  }

  Future<void> _apply(MediaItem? item) async {
    final directory = await (_directory ??= _resolveDirectory());
    if (directory == null) return;

    final recent = [
      for (final album in _recent)
        {'id': album.id, 'title': album.title, 'cover': album.cover},
    ];
    final Map<String, Object?> json;
    if (_signedOut) {
      json = const {'signedOut': true};
    } else if (item == null) {
      json = {if (recent.isNotEmpty) 'recent': recent};
    } else {
      if (item.id != _coverId) await _refreshCover(directory, item);
      final cover = _cover;
      json = {
        'title': item.title,
        'artist': item.artist ?? '',
        'playing': _playing,
        'liked': _liked,
        'shuffle': _shuffle,
        'repeat': _repeat.name,
        'cover': cover == null ? null : p.join(directory.path, coverFile),
        'background': cover?.background.toARGB32(),
        'foreground': cover?.foreground.toARGB32(),
        if (recent.isNotEmpty) 'recent': recent,
      };
    }

    final encoded = jsonEncode(json);
    if (encoded == _published) return;
    if (json.isEmpty && _published == null) return;
    await _replace(
      File(p.join(directory.path, snapshotFile)),
      utf8.encode(encoded),
    );
    _published = encoded;
    await _host.reload();
  }

  Future<Directory?> _resolveDirectory() async {
    final path = await _host.directory();
    if (path == null) return null;
    return Directory(path).create(recursive: true);
  }

  Future<void> _refreshCover(Directory directory, MediaItem item) async {
    final file = File(p.join(directory.path, coverFile));
    final pixels = await _writeArtwork(item.artUri, file, widgetCoverSize);
    WidgetArtwork? cover;
    if (pixels != null) {
      try {
        cover = await widgetArtworkColors(pixels);
      } on Object catch (error) {
        debugPrint('[HomeWidget] artwork colours failed: $error');
      }
    }
    _coverId = item.id;
    _cover = cover;
  }

  Future<List<int>?> _writeArtwork(Uri? uri, File file, int size) async {
    final temp = File('${file.path}.tmp');
    List<int>? pixels;
    try {
      final source = await _artworkSource(uri);
      if (source != null) {
        pixels = await _host.artwork(
          source: source,
          target: temp.path,
          size: size,
        );
      }
      if (pixels != null && temp.existsSync()) {
        await temp.rename(file.path);
        return pixels;
      }
    } on Object catch (error) {
      debugPrint('[HomeWidget] artwork failed: $error');
    }
    if (temp.existsSync()) await temp.delete();
    if (file.existsSync()) await file.delete();
    return null;
  }

  Future<void> _replace(File file, List<int> bytes) async {
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
  }
}
