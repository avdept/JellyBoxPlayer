import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    if (song == null) {
      if (_metadata == null) return;
      _metadata = null;
      _run(controls.clearMetadata());
      return;
    }

    final art = song.artUri;
    final metadata = smtc.MusicMetadata(
      title: song.title,
      artist: song.artist ?? '',
      album: song.album ?? '',
      thumbnail: (art != null && art.hasScheme) ? art.toString() : null,
    );
    if (metadata == _metadata) return;
    final droppedArtwork =
        _metadata?.thumbnail != null && metadata.thumbnail == null;
    _metadata = metadata;
    _run(
      droppedArtwork
          ? controls.clearMetadata().then(
              (_) => controls.updateMetadata(metadata),
            )
          : controls.updateMetadata(metadata),
    );
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
