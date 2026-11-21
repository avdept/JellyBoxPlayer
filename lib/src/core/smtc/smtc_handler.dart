import 'dart:async';
import 'dart:io'
    show
        ContentType,
        File,
        HttpRequest,
        HttpServer,
        HttpStatus,
        InternetAddress,
        Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/now_playing_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:just_audio_background/just_audio_background.dart'
    show MediaItem;
import 'package:smtc_windows/smtc_windows.dart' as smtc;

class SmtcHandler {
  static const _positionEpsilon = Duration(seconds: 1);

  static const _config = smtc.SMTCConfig(
    playEnabled: true,
    pauseEnabled: true,
    stopEnabled: true,
    nextEnabled: true,
    prevEnabled: true,
    fastForwardEnabled: false,
    rewindEnabled: false,
  );

  static const _artworkTimeout = Duration(seconds: 5);

  static var _generation = 0;
  static HttpServer? _server;
  static final _served = <String, String>{};
  static smtc.SMTCWindows? _controls;
  static smtc.MusicMetadata? _metadata;
  static smtc.PlaybackStatus? _status;
  static Duration? _duration;
  static Duration _position = Duration.zero;
  static var _enabled = false;
  static bool? _shuffle;

  static Future<void> initialize(ProviderContainer ref) async {
    if (!Platform.isWindows || _controls != null) return;

    final smtc.SMTCWindows controls;
    try {
      await smtc.SMTCWindows.initialize();
      controls = smtc.SMTCWindows(enabled: false, config: _config);
    } on Object catch (error) {
      debugPrint('[SMTC] unavailable: $error');
      return;
    }
    _controls = controls;

    controls.buttonPressStream.listen((button) => _onButton(ref, button));
    controls.shuffleChangeStream.listen(
      (enabled) => ref
          .read(playbackProvider.notifier)
          .setShuffle(enabled: enabled)
          .ignore(),
    );

    ref
      ..listen(
        nowPlayingProvider,
        fireImmediately: true,
        (previous, next) => _onNowPlaying(next),
      )
      ..listen(
        playbackProvider,
        fireImmediately: true,
        (previous, next) => _onPlayback(next),
      );
  }

  static void _onButton(ProviderContainer ref, smtc.PressedButton button) {
    final playback = ref.read(playbackProvider.notifier);
    switch (button) {
      case smtc.PressedButton.play:
        playback.resume().ignore();
      case smtc.PressedButton.pause:
        playback.pause().ignore();
      case smtc.PressedButton.next:
        playback.next().ignore();
      case smtc.PressedButton.previous:
        playback.prev().ignore();
      case smtc.PressedButton.stop:
        playback.stop().ignore();
      case smtc.PressedButton.fastForward:
      case smtc.PressedButton.rewind:
      case smtc.PressedButton.record:
      case smtc.PressedButton.channelUp:
      case smtc.PressedButton.channelDown:
        break;
    }
  }

  static void _onNowPlaying(MediaItem? song) {
    final controls = _controls;
    if (controls == null) return;

    final generation = ++_generation;
    if (song == null) {
      if (_metadata == null) return;
      _metadata = null;
      _run(controls.clearMetadata());
      return;
    }

    _run(_publish(controls, song, generation));
  }

  static Future<void> _publish(
    smtc.SMTCWindows controls,
    MediaItem song,
    int generation,
  ) async {
    final thumbnail = await _thumbnailFor(song.artUri);
    if (generation != _generation) return;

    final metadata = smtc.MusicMetadata(
      title: song.title,
      artist: song.artist ?? '',
      album: song.album ?? '',
      thumbnail: thumbnail,
    );
    if (metadata == _metadata) return;
    final droppedArtwork =
        _metadata?.thumbnail != null && metadata.thumbnail == null;
    _metadata = metadata;
    if (droppedArtwork) await controls.clearMetadata();
    await controls.updateMetadata(metadata);
  }

  static Future<String?> _thumbnailFor(Uri? art) async {
    if (art == null) return null;
    String? path;
    if (art.isScheme('file')) {
      path = art.toFilePath();
    } else if (art.isScheme('http') || art.isScheme('https')) {
      path = await ArtworkCache.instance
          .pathFor(art.toString())
          .timeout(_artworkTimeout, onTimeout: () => null);
    }
    if (path == null || !File(path).existsSync()) return null;
    return _serve(path);
  }

  static Future<String?> _serve(String path) async {
    try {
      var server = _server;
      if (server == null) {
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        _server = server;
        server.listen(_handleArtwork, onError: (Object _) {});
      }
      final id = path.hashCode.toRadixString(16);
      _served[id] = path;
      return 'http://127.0.0.1:${server.port}/art/$id';
    } on Object catch (error) {
      debugPrint('[SMTC] artwork server failed: $error');
      return null;
    }
  }

  static Future<void> _handleArtwork(HttpRequest request) async {
    final response = request.response;
    try {
      final id = request.uri.pathSegments.lastOrNull;
      final path = id == null ? null : _served[id];
      final file = path == null ? null : File(path);
      if (file == null || !file.existsSync()) {
        response.statusCode = HttpStatus.notFound;
      } else {
        final bytes = await file.readAsBytes();
        response
          ..headers.contentType = ContentType.parse(_mimeOf(bytes))
          ..contentLength = bytes.length
          ..add(bytes);
      }
    } on Object catch (error) {
      debugPrint('[SMTC] artwork request failed: $error');
    } finally {
      await response.close();
    }
  }

  static String _mimeOf(List<int> b) {
    if (b.length > 3 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b.length > 3 && b[0] == 0x47 && b[1] == 0x49) return 'image/gif';
    if (b.length > 11 && b[8] == 0x57 && b[9] == 0x45) return 'image/webp';
    return 'image/jpeg';
  }

  static void _onPlayback(PlaybackState state) {
    final controls = _controls;
    if (controls == null) return;

    final enabled = state.songs.isNotEmpty;
    if (enabled != _enabled) {
      _enabled = enabled;
      _run(enabled ? controls.enableSmtc() : controls.disableSmtc());
    }
    if (!enabled) return;

    final status = switch (state.status) {
      PlaybackStatus.playing => smtc.PlaybackStatus.playing,
      PlaybackStatus.paused => smtc.PlaybackStatus.paused,
      PlaybackStatus.buffering => smtc.PlaybackStatus.changing,
      PlaybackStatus.stopped ||
      PlaybackStatus.error => smtc.PlaybackStatus.stopped,
    };
    if (status != _status) {
      _status = status;
      _run(controls.setPlaybackStatus(status));
    }

    if (state.shuffleEnabled != _shuffle) {
      _shuffle = state.shuffleEnabled;
      _run(controls.setShuffleEnabled(state.shuffleEnabled));
    }

    final duration = state.totalDuration ?? Duration.zero;
    final position = state.position;
    if (duration != _duration ||
        (position - _position).abs() >= _positionEpsilon) {
      _duration = duration;
      _position = position;
      _run(
        controls.updateTimeline(
          smtc.PlaybackTimeline(
            startTimeMs: 0,
            endTimeMs: duration.inMilliseconds,
            positionMs: position.inMilliseconds,
          ),
        ),
      );
    }
  }

  static void _run(Future<void> call) => unawaited(
    call.catchError(
      (Object error) => debugPrint('[SMTC] update failed: $error'),
    ),
  );
}
