import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/core/discord/discord_activity.dart';
import 'package:jplayer/src/core/discord/discord_presence_client.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/now_playing_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:just_audio_background/just_audio_background.dart'
    show MediaItem;

bool get supportsDiscordPresence {
  if (kIsWeb) return false;
  if (Platform.isMacOS) return kDirectDownloadBuild;
  return Platform.isWindows || Platform.isLinux;
}

class DiscordPresenceHandler {
  static const _artworkAsset = 'jellybox';
  static const _seekTolerance = Duration(seconds: 4);

  static DiscordPresenceClient? _client;
  static ProviderContainer? _container;
  static String? _timelineId;
  static DateTime? _timelineStart;
  static DateTime? _timelineEnd;

  static void initialize(
    ProviderContainer ref, {
    DiscordPresenceClient? client,
  }) {
    if (_client != null) return;
    if (client == null && !supportsDiscordPresence) return;

    _container = ref;
    _client =
        client ?? DiscordPresenceClient(applicationId: discordApplicationId);

    ref
      ..listen(
        settingProvider(AppSetting.discordRichPresence),
        fireImmediately: true,
        (previous, next) => _onEnabledChanged(enabled: next),
      )
      ..listen(nowPlayingProvider, (previous, next) => _update())
      ..listen(playbackProvider, (previous, next) => _update());
  }

  @visibleForTesting
  static void reset() {
    _client = null;
    _container = null;
    _resetTimeline();
  }

  static void _onEnabledChanged({required bool enabled}) {
    final client = _client;
    if (client == null) return;

    if (enabled) {
      client.start();
      _update();
    } else {
      _resetTimeline();
      unawaited(client.stop());
    }
  }

  static void _update() {
    final client = _client;
    final container = _container;
    if (client == null || container == null) return;
    if (!container.read(settingProvider(AppSetting.discordRichPresence))) {
      return;
    }

    client.setActivity(
      _activityFor(
        container.read(nowPlayingProvider),
        container.read(playbackProvider),
      ),
    );
  }

  static DiscordActivity? _activityFor(MediaItem? song, PlaybackState state) {
    if (song == null || !_isAudible(song, state)) {
      _resetTimeline();
      return null;
    }

    final timeline = _timelineFor(song, state);
    return DiscordActivity.listening(
      title: song.title,
      artist: song.artist,
      album: song.album,
      largeImage: _artworkAsset,
      start: timeline.start,
      end: timeline.end,
    );
  }

  static bool _isAudible(MediaItem song, PlaybackState state) =>
      state.status == PlaybackStatus.playing ||
      (state.status == PlaybackStatus.buffering && _timelineId == song.id);

  static ({DateTime? start, DateTime? end}) _timelineFor(
    MediaItem song,
    PlaybackState state,
  ) {
    if (state.status == PlaybackStatus.buffering) {
      return (start: _timelineStart, end: _timelineEnd);
    }

    final now = DateTime.now();
    final start = _timelineStart;
    if (_timelineId == song.id && start != null) {
      final drift = now.difference(start) - state.position;
      if (drift.abs() < _seekTolerance) {
        return (start: start, end: _timelineEnd);
      }
    }

    final anchor = now.subtract(state.position);
    final duration = song.duration ?? state.totalDuration;
    _timelineId = song.id;
    _timelineStart = anchor;
    _timelineEnd = duration == null ? null : anchor.add(duration);
    return (start: _timelineStart, end: _timelineEnd);
  }

  static void _resetTimeline() {
    _timelineId = null;
    _timelineStart = null;
    _timelineEnd = null;
  }
}
