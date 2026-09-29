import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_screen_widgets/home_screen_widgets.dart';
import 'package:jplayer/src/core/home_widget/widget_artwork.dart';
import 'package:jplayer/src/domain/models/models.dart';
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
}

typedef WidgetArtworkLoader = Future<WidgetArtwork?> Function(MediaItem item);

typedef _Published = ({
  String id,
  String title,
  String artist,
  bool playing,
  bool liked,
  bool shuffle,
  LoopMode repeat,
});

enum _Placeholder { empty, signedOut }

class NowPlayingWidgetSync {
  NowPlayingWidgetSync({
    WidgetHost host = const PluginWidgetHost(),
    WidgetArtworkLoader artwork = loadWidgetArtwork,
  }) : _host = host,
       _artwork = artwork;

  static const snapshotFile = 'now_playing.json';
  static const coverFile = 'now_playing_cover.png';

  final WidgetHost _host;
  final WidgetArtworkLoader _artwork;

  Future<Directory?>? _directory;
  Future<void>? _draining;
  var _running = false;
  var _dirty = false;
  Object? _published;
  var _signedOut = false;
  String? _coverId;
  WidgetArtwork? _cover;

  MediaItem? _item;
  var _playing = false;
  var _liked = false;
  var _shuffle = false;
  LoopMode _repeat = LoopMode.off;

  static void initialize(ProviderContainer ref) {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    NowPlayingWidgetSync().attach(ref);
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
        _schedule();
      },
    );
    (loopModes ?? ref.read(playerProvider).loopModeStream).listen((mode) {
      _repeat = mode;
      _schedule();
    });
  }

  @visibleForTesting
  Future<void> get idle => _draining ?? Future<void>.value();

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
    final published = _signedOut
        ? _Placeholder.signedOut
        : item == null
        ? _Placeholder.empty
        : (
            id: item.id,
            title: item.title,
            artist: item.artist ?? '',
            playing: _playing,
            liked: _liked,
            shuffle: _shuffle,
            repeat: _repeat,
          );
    if (published == _published) return;
    if (published == _Placeholder.empty && _published == null) return;

    final directory = await (_directory ??= _resolveDirectory());
    if (directory == null) return;

    if (published == _Placeholder.signedOut) {
      await _writeJson(directory, const {'signedOut': true});
    } else if (published is! _Published) {
      await _writeJson(directory, const <String, Object?>{});
    } else {
      if (published.id != _coverId) await _refreshCover(directory, item!);
      final cover = _cover;
      await _writeJson(directory, {
        'title': published.title,
        'artist': published.artist,
        'playing': published.playing,
        'liked': published.liked,
        'shuffle': published.shuffle,
        'repeat': published.repeat.name,
        'cover': cover == null ? null : p.join(directory.path, coverFile),
        'background': cover?.background.toARGB32(),
        'foreground': cover?.foreground.toARGB32(),
      });
    }
    _published = published;
    await _host.reload();
  }

  Future<Directory?> _resolveDirectory() async {
    final path = await _host.directory();
    if (path == null) return null;
    return Directory(path).create(recursive: true);
  }

  Future<void> _refreshCover(Directory directory, MediaItem item) async {
    WidgetArtwork? cover;
    try {
      cover = await _artwork(item);
    } on Object catch (error) {
      debugPrint('[HomeWidget] artwork failed: $error');
    }
    final file = File(p.join(directory.path, coverFile));
    if (cover == null) {
      if (file.existsSync()) await file.delete();
    } else {
      await _replace(file, cover.png);
    }
    _coverId = item.id;
    _cover = cover;
  }

  Future<void> _writeJson(Directory directory, Map<String, Object?> json) =>
      _replace(
        File(p.join(directory.path, snapshotFile)),
        utf8.encode(jsonEncode(json)),
      );

  Future<void> _replace(File file, List<int> bytes) async {
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
  }
}
