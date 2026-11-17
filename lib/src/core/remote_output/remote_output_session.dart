import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/android_auto/android_auto_handler.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/platform/volume_keys.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart'
    show cloudProvider, playingElsewhereProvider;
import 'package:jplayer/src/domain/providers/device_volume_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart'
    show playbackProvider;
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/domain/providers/volume_keys_provider.dart';
import 'package:jplayer/src/domain/providers/volume_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

final remoteOutputActiveProvider = Provider<bool>(
  (ref) =>
      ref.watch(playingElsewhereProvider) ||
      ref.watch(playbackTargetProvider.select((target) => target.kind)) !=
          PlaybackTargetKind.local,
);

class RemoteOutputSession extends BaseAudioHandler with SeekHandler {
  RemoteOutputSession(
    this._ref, {
    void Function(AudioHandler? handler)? install,
    DateTime Function()? now,
  }) : _install =
           install ??
           ((handler) => JustAudioBackground.remoteHandler = handler),
       _now = now ?? DateTime.now {
    _ref
      ..listen(playbackProvider, (_, _) => _schedule())
      ..listen(playbackTargetProvider, (_, _) => _schedule())
      ..listen(cloudProvider, (_, _) => _schedule())
      ..listen(deviceVolumeProvider, (_, _) => _schedule());
    _schedule();
  }

  static const volumeSteps = 100;
  static const driftTolerance = Duration(milliseconds: 1500);

  static void initialize(ProviderContainer ref) {
    if (!Platform.isAndroid) return;
    RemoteOutputSession(ref);
  }

  final ProviderContainer _ref;
  final void Function(AudioHandler? handler) _install;
  final DateTime Function() _now;
  bool _scheduled = false;
  bool? _installed;

  BarControls get _controls => _ref.read(barControlsProvider);

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(_sync);
  }

  void _sync() {
    _scheduled = false;
    final item = _ref.read(barMediaItemProvider);
    final changed = item?.id != mediaItem.valueOrNull?.id;
    if (changed) {
      mediaItem.add(
        item?.copyWith(artUri: AndroidAutoHandler.autoArtUri(item.artUri)),
      );
    }
    _broadcast(force: changed);
    _setVolume(_ref.read(deviceVolumeProvider));
    final active = _ref.read(remoteOutputActiveProvider);
    if (_installed != active) {
      _installed = active;
      _install(active ? this : null);
    }
  }

  void _broadcast({bool force = false}) {
    final progress = _ref.read(barProgressProvider);
    final playing = _ref.read(barPlayingProvider);
    final processing = _processingState(progress.stopped);
    final now = _now();
    final last = playbackState.valueOrNull;
    if (!force &&
        last != null &&
        last.playing == playing &&
        last.processingState == processing) {
      final expected = last.playing
          ? last.updatePosition + now.difference(last.updateTime)
          : last.updatePosition;
      if ((progress.position - expected).abs() < driftTolerance) return;
    }
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processing,
        playing: playing,
        updatePosition: progress.position,
        updateTime: now,
      ),
    );
  }

  AudioProcessingState _processingState(bool stopped) {
    if (mediaItem.valueOrNull == null || stopped) {
      return AudioProcessingState.idle;
    }
    if (!_ref.read(playingElsewhereProvider) &&
        _ref.read(playbackProvider).status == PlaybackStatus.buffering) {
      return AudioProcessingState.buffering;
    }
    return AudioProcessingState.ready;
  }

  void _setVolume(VolumeState volume) {
    androidPlaybackInfo.add(
      RemoteAndroidPlaybackInfo(
        volumeControlType: AndroidVolumeControlType.absolute,
        maxVolume: volumeSteps,
        volume: (volume.effectiveLevel * volumeSteps).round(),
      ),
    );
  }

  @override
  Future<void> play() => _controls.play();

  @override
  Future<void> pause() => _controls.pause();

  @override
  Future<void> stop() => _controls.stop();

  @override
  Future<void> seek(Duration position) => _controls.seek(position);

  @override
  Future<void> skipToNext() => _controls.next();

  @override
  Future<void> skipToPrevious() => _controls.previous();

  @override
  Future<void> androidSetRemoteVolume(int volumeIndex) => _ref
      .read(deviceVolumeProvider.notifier)
      .setLevel(volumeIndex / volumeSteps);

  @override
  Future<void> androidAdjustRemoteVolume(
    AndroidVolumeDirection direction,
  ) async {
    final key = switch (direction.index) {
      1 => VolumeKey.up,
      -1 => VolumeKey.down,
      _ => null,
    };
    if (key != null) _ref.read(volumeKeysProvider.notifier).press(key);
  }
}
