import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optional_features/jellybox_cloud.dart';
import 'package:jplayer/main.dart' as app show deviceId;
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/volume_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';

String continuityDeviceName() {
  if (kIsWeb) return 'Browser';
  if (Platform.isMacOS) return 'Mac';
  if (Platform.isIOS) return 'iPhone';
  if (Platform.isAndroid) return 'Android phone';
  if (Platform.isWindows) return 'Windows PC';
  if (Platform.isLinux) return 'Linux desktop';
  return 'JellyBox';
}

String continuityPlatformName() {
  if (kIsWeb) return 'web';
  return Platform.operatingSystem;
}

class CloudHostAdapter implements CloudHost<LibraryItem> {
  CloudHostAdapter(this._ref) {
    _ref.listen(playbackProvider, (_, next) => _playback.add(_snapshot(next)));
    _loopMode = _ref
        .read(playerProvider)
        .loopModeStream
        .distinct()
        .skip(1)
        .listen((_) {
          if (_ref.exists(playbackProvider)) _playback.add(playback);
        });
  }

  final Ref _ref;

  final _playback = StreamController<CloudPlayback?>.broadcast();
  late final StreamSubscription<LoopMode> _loopMode;
  ProviderSubscription<VolumeState>? _volume;

  @override
  String get deviceId => app.deviceId;

  @override
  String get deviceName => continuityDeviceName();

  @override
  String get platform => continuityPlatformName();

  @override
  String? get backendRef => _ref.read(currentServerIdProvider);

  @override
  String? get benchUserId {
    final user = _ref.read(currentUserProvider);
    final serverId = _ref.read(currentServerIdProvider);
    if (user == null || serverId == null) return null;
    return '$serverId:${user.userId}';
  }

  @override
  CloudPlayback? get playback => _snapshot(_ref.read(playbackProvider));

  @override
  Stream<CloudPlayback?> get playbackChanges => _playback.stream;

  @override
  Future<List<LibraryItem>> itemsByIds(List<String> ids) =>
      _ref.read(mediaServerClientProvider).getItemsByIds(ids);

  @override
  Future<LibraryItem?> albumById(String id) async {
    try {
      return await _ref
          .read(mediaServerClientProvider)
          .getItem(id, kind: ItemKind.album);
    } on Object {
      return null;
    }
  }

  @override
  LibraryItem placeholderAlbumFor(LibraryItem song) => LibraryItem(
    id: song.albumId ?? song.id,
    name: song.albumName ?? song.name,
    kind: ItemKind.album,
  );

  @override
  Future<void> play({
    required List<LibraryItem> songs,
    required int index,
    required LibraryItem? album,
    required Duration position,
    required bool autoPlay,
    required bool shuffle,
  }) async {
    final playback = _ref.read(playbackProvider.notifier);
    await playback.play(
      songs[index],
      songs,
      album ?? placeholderAlbumFor(songs[index]),
      initialPosition: position,
      autoPlay: autoPlay,
      reshuffle: false,
    );
    playback.adoptShuffle(enabled: shuffle);
  }

  @override
  Future<void> pause() => _ref.read(playbackProvider.notifier).pause();

  @override
  Future<void> resume() => _ref.read(playbackProvider.notifier).resume();

  @override
  Future<void> skipNext() => _ref.read(playbackProvider.notifier).next();

  @override
  Future<void> skipPrevious() => _ref.read(playbackProvider.notifier).prev();

  @override
  Future<void> seek(Duration position) =>
      _ref.read(playbackProvider.notifier).seek(position);

  @override
  Future<void> setShuffle({required bool enabled}) =>
      _ref.read(playbackProvider.notifier).setShuffle(enabled: enabled);

  @override
  Future<void> setRepeat(String mode) =>
      _ref.read(playerProvider).setLoopMode(switch (mode) {
        'all' => LoopMode.all,
        'one' => LoopMode.one,
        _ => LoopMode.off,
      });

  @override
  Future<void> setVolume(double level) async {
    await _ref.read(volumeProvider.notifier).setLevel(level);
    _watchVolume();
  }

  @override
  Future<void> skipTo(int index) =>
      _ref.read(playbackProvider.notifier).skipTo(index, autoPlay: true);

  @override
  bool get rendersLocally =>
      _ref.read(playbackProvider.notifier).target.kind ==
      PlaybackTargetKind.local;

  @override
  Duration get bufferedPosition => _ref.read(playerProvider).bufferedPosition;

  @override
  /// How long until the player reports a position past [from], or null if
  /// nothing ever says so.
  ///
  /// `updatePosition` is not a dependable signal — `media_kit` on desktop
  /// often never emits one that passes the target — so null is a normal
  /// outcome and means "not observed", never "slow". The wait is short
  /// because a report that arrives later than the next handoff gets counted
  /// against the wrong one.
  Future<int?> millisUntilAudible(Duration from) {
    final clock = Stopwatch()..start();
    return _ref
        .read(playerProvider)
        .playbackEventStream
        .firstWhere(
          (event) =>
              event.updatePosition > from + const Duration(milliseconds: 20),
        )
        .then<int?>((_) => clock.elapsedMilliseconds)
        .timeout(const Duration(seconds: 4), onTimeout: () => null);
  }

  @override
  Future<String?> readSecret(String key) =>
      _ref.read(secureStorageProvider).read(key: key);

  @override
  Future<void> writeSecret(String key, String value) =>
      _ref.read(secureStorageProvider).write(key: key, value: value);

  @override
  Future<void> deleteSecret(String key) =>
      _ref.read(secureStorageProvider).delete(key: key);

  void dispose() {
    _volume?.close();
    unawaited(_loopMode.cancel());
    unawaited(_playback.close());
  }

  void _watchVolume() {
    if (_volume != null || !_ref.exists(volumeProvider)) return;
    _volume = _ref.listen(volumeProvider, (_, _) => _playback.add(playback));
  }

  double get _volumeLevel => _ref.exists(volumeProvider)
      ? _ref.read(volumeProvider).effectiveLevel
      : _ref
            .read(appSettingsProvider.notifier)
            .numberOf(AppSetting.playerVolume)
            .clamp(0.0, 1.0);

  CloudPlayback? _snapshot(PlaybackState playback) {
    _watchVolume();
    if (playback.songs.isEmpty) return null;
    return CloudPlayback(
      itemIds: [for (final song in playback.songs) song.id],
      albumId: playback.album?.id,
      index: playback.currentMediaIndex ?? 0,
      position: playback.position,
      playing: playback.status.isPlaying,
      shuffle: playback.shuffleEnabled,
      repeat: _ref.read(playerProvider).loopMode.name,
      volume: _volumeLevel,
    );
  }
}
