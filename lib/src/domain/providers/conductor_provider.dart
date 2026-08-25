import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/conductor/conductor_client.dart';
import 'package:jplayer/src/data/conductor/conductor_models.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final conductorUrlProvider =
    StateNotifierProvider<ConductorUrlNotifier, String>((ref) {
      return ConductorUrlNotifier(
        ref.watch(sharedPreferencesProvider).valueOrNull,
      );
    });

class ConductorUrlNotifier extends StateNotifier<String> {
  ConductorUrlNotifier(this._prefs) : super(_prefs?.getString(_key) ?? '');

  static const _key = 'conductor_url';

  final SharedPreferences? _prefs;

  String get url => state;

  set url(String value) {
    state = value.trim();
    final prefs = _prefs;
    if (prefs != null) unawaited(prefs.setString(_key, state));
  }
}

final conductorProvider =
    StateNotifierProvider<ConductorNotifier, ConductorUiState>((ref) {
      final notifier = ConductorNotifier(ref);
      ref.onDispose(notifier.shutdown);
      return notifier;
    });

@immutable
class ConductorUiState {
  const ConductorUiState({
    this.status = ConductorStatus.off,
    this.devices = const [],
    this.lastHandoffMs,
    this.error,
  });

  final ConductorStatus status;
  final List<ConductorDevice> devices;

  final int? lastHandoffMs;

  final String? error;

  bool get isConnected =>
      status == ConductorStatus.listening ||
      status == ConductorStatus.rendering;

  List<ConductorDevice> get targets => devices.where((d) => !d.isSelf).toList();

  ConductorUiState copyWith({
    ConductorStatus? status,
    List<ConductorDevice>? devices,
    int? lastHandoffMs,
    String? error,
    bool clearError = false,
  }) => ConductorUiState(
    status: status ?? this.status,
    devices: devices ?? this.devices,
    lastHandoffMs: lastHandoffMs ?? this.lastHandoffMs,
    error: clearError ? null : (error ?? this.error),
  );
}

class ConductorNotifier extends StateNotifier<ConductorUiState> {
  ConductorNotifier(this._ref) : super(const ConductorUiState()) {
    _ref
      ..listen(conductorUrlProvider, (_, _) => unawaited(_reconcile()))
      ..listen(currentUserProvider, (_, _) => unawaited(_reconcile()))
      ..listen(playbackProvider, _onLocalPlaybackChanged);

    unawaited(_reconcile());
  }

  final Ref _ref;

  ConductorClient? _client;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Timer? _positionTimer;

  var _published = const SessionDoc();
  DateTime? _publishedAt;

  var _startupEstimateMs = 0;

  var _applyingRemote = false;

  ConductorClient? get client => _client;

  Future<void> _reconcile() async {
    final url = _ref.read(conductorUrlProvider);
    final user = _ref.read(currentUserProvider);
    final serverId = _ref.read(currentServerIdProvider);

    await _teardown();

    if (url.isEmpty || user == null || serverId == null) {
      state = const ConductorUiState();
      return;
    }

    final Uri endpoint;
    try {
      endpoint = Uri.parse(url.contains('://') ? url : 'http://$url');
    } on FormatException {
      state = state.copyWith(
        status: ConductorStatus.error,
        error: 'Conductor URL is not a valid address',
      );
      return;
    }

    final client = _client = ConductorClient(
      endpoint: endpoint,
      userId: '$serverId:${user.userId}',
      deviceId: deviceId,
      deviceName: _deviceName(),
      platform: _platformName(),
    );

    _subscriptions.addAll([
      client.statusStream.listen(
        (status) => state = state.copyWith(status: status, clearError: true),
      ),
      client.devicesStream.listen(
        (devices) => state = state.copyWith(devices: devices),
      ),
      client.handoffStream.listen(_onHandoff),
      client.rendererStream.listen(_onRendererChanged),
    ]);

    await client.connect();
    _startPositionHeartbeat();
  }

  Future<void> _teardown() async {
    _positionTimer?.cancel();
    _positionTimer = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _client?.dispose();
    _client = null;
  }

  Future<void> shutdown() => _teardown();

  void _onLocalPlaybackChanged(PlaybackState? previous, PlaybackState next) {
    final client = _client;
    if (client == null || _applyingRemote) return;

    final startedPlaying =
        next.status.isPlaying && !(previous?.status.isPlaying ?? false);
    if (startedPlaying && !client.isRenderer) {
      unawaited(client.announceRenderer());
    }

    if (!client.isRenderer && client.rendererId != null && !startedPlaying) {
      return;
    }

    final doc = _docFrom(next);
    if (doc == null) return;
    if (!_worthPublishing(doc)) return;

    _publish(client, doc);
  }

  void _onRendererChanged(String? rendererId) {
    final client = _client;
    if (client == null || rendererId == null || _applyingRemote) return;
    if (rendererId == client.deviceId) return;

    final playback = _ref.read(playbackProvider);
    if (!playback.status.isPlaying) return;

    _applyingRemote = true;
    unawaited(
      _ref
          .read(playbackProvider.notifier)
          .pause()
          .whenComplete(() => _applyingRemote = false),
    );
  }

  bool _worthPublishing(SessionDoc doc) {
    if (doc.differsStructurallyFrom(_published)) return true;

    final publishedAt = _publishedAt;
    if (publishedAt == null) return true;

    final elapsed = _published.playing
        ? DateTime.now().difference(publishedAt).inMilliseconds
        : 0;
    final predicted = _published.trackPositionMs + elapsed;

    return (doc.trackPositionMs - predicted).abs() > 1500;
  }

  void _publish(ConductorClient client, SessionDoc doc) {
    _published = doc;
    _publishedAt = DateTime.now();
    unawaited(client.publish(doc));
  }

  void _startPositionHeartbeat() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final client = _client;
      if (client == null || !client.isRenderer) return;

      final doc = _docFrom(_ref.read(playbackProvider));
      if (doc == null || !doc.playing) return;

      _publish(client, doc);
    });
  }

  SessionDoc? _docFrom(PlaybackState playback) {
    if (playback.songs.isEmpty) return null;
    final serverId = _ref.read(currentServerIdProvider);
    if (serverId == null) return null;

    return SessionDoc(
      backendRef: serverId,
      albumId: playback.album?.id,
      itemIds: [for (final song in playback.songs) song.id],
      queuePosition: playback.currentMediaIndex ?? 0,
      trackPositionMs: playback.position.inMilliseconds,
      playing: playback.status.isPlaying,
    );
  }

  Future<void> _onHandoff(HandoffRequest request) async {
    if (!request.isForUs) {
      final playback = _ref.read(playbackProvider);
      if (playback.status.isPlaying) {
        await _ref.read(playbackProvider.notifier).pause();
      }
      return;
    }

    final client = _client;
    if (client == null) return;

    final doc = request.doc;
    final serverId = _ref.read(currentServerIdProvider);

    if (doc.backendRef != null && doc.backendRef != serverId) {
      await client.reportHandoffFailed('signed into a different media server');
      state = state.copyWith(
        error:
            'That queue is from another server this device is not signed into',
      );
      return;
    }

    if (doc.isEmpty) {
      await client.reportHandoffFailed('empty queue');
      return;
    }

    _applyingRemote = true;
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        await client.reportHandoffFailed('not signed in');
        return;
      }

      final backend = _ref.read(mediaServerClientProvider);

      final resolved = await Future.wait([
        backend.getItemsByIds(userId: user.userId, ids: doc.itemIds),
        if (doc.albumId case final albumId?)
          backend.getItem(albumId)
        else
          Future<LibraryItem?>.value(),
      ]);

      final songs = resolved[0]! as List<LibraryItem>;
      if (songs.isEmpty) {
        await client.reportHandoffFailed('none of those tracks exist here');
        return;
      }

      final index = doc.queuePosition.clamp(0, songs.length - 1);
      final album =
          resolved[1] as LibraryItem? ?? _placeholderAlbum(songs[index]);

      final resumeAt = request.positionAt(
        DateTime.now(),
        startupAllowance: Duration(milliseconds: _startupEstimateMs),
      );

      final startedAt = DateTime.now();

      await _ref
          .read(playbackProvider.notifier)
          .play(
            songs[index],
            songs,
            album,
            initialPosition: resumeAt,
            autoPlay: doc.playing,
          );

      _rememberStartupCost(DateTime.now().difference(startedAt));
      unawaited(_verifySeek(resumeAt));

      final elapsed = DateTime.now().difference(request.receivedAt);
      state = state.copyWith(
        lastHandoffMs: elapsed.inMilliseconds,
        clearError: true,
      );
      _published = doc;

      await client.reportHandoffDone(audibleMs: elapsed.inMilliseconds);
      debugPrint('[conductor] handoff applied in ${elapsed.inMilliseconds}ms');
    } on Object catch (error, stack) {
      debugPrint('[conductor] handoff failed: $error\n$stack');
      await client.reportHandoffFailed('$error');
      state = state.copyWith(error: 'Could not take over playback: $error');
    } finally {
      _applyingRemote = false;
    }
  }

  Future<void> _verifySeek(Duration target) async {
    if (target < const Duration(seconds: 10)) return;

    final player = _ref.read(playerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final buffered = player.bufferedPosition;
    if (buffered >= target - const Duration(seconds: 5)) return;

    debugPrint(
      '[conductor] stream ignored the seek — buffered at '
      '${buffered.inSeconds}s but asked for ${target.inSeconds}s. Re-seeking.',
    );

    await _ref.read(playbackProvider.notifier).seek(target);
    unawaited(
      _client?.reportSeekCorrected(
            targetMs: target.inMilliseconds,
            bufferedMs: buffered.inMilliseconds,
          ) ??
          Future<void>.value(),
    );
  }

  void _rememberStartupCost(Duration measured) {
    const maxAllowanceMs = 2000;
    final sample = measured.inMilliseconds.clamp(0, maxAllowanceMs);

    _startupEstimateMs = _startupEstimateMs == 0
        ? sample
        : ((sample * 0.6) + (_startupEstimateMs * 0.4)).round();
  }

  LibraryItem _placeholderAlbum(LibraryItem song) => LibraryItem(
    id: song.albumId ?? song.id,
    name: song.albumName ?? song.name,
    kind: ItemKind.album,
  );

  Future<void> handoffTo(String deviceId) async {
    final client = _client;
    if (client == null) return;
    try {
      final doc = _docFrom(_ref.read(playbackProvider));
      if (doc != null) {
        _published = doc;
        await client.publish(doc);
      }
      await client.handoffTo(deviceId);

      _applyingRemote = true;
      try {
        await _ref.read(playbackProvider.notifier).pause();
      } finally {
        _applyingRemote = false;
      }
    } on Object catch (error) {
      state = state.copyWith(error: '$error');
    }
  }

  Future<void> claimHere() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.claimHere();
    } on Object catch (error) {
      state = state.copyWith(error: '$error');
    }
  }

  Future<void> reconnect() => _reconcile();
}

String _deviceName() {
  if (kIsWeb) return 'Browser';
  if (Platform.isMacOS) return 'Mac';
  if (Platform.isIOS) return 'iPhone';
  if (Platform.isAndroid) return 'Android phone';
  if (Platform.isWindows) return 'Windows PC';
  if (Platform.isLinux) return 'Linux desktop';
  return 'JellyBox';
}

String _platformName() {
  if (kIsWeb) return 'web';
  return Platform.operatingSystem;
}
