import 'dart:async';

import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/cast/cast_media_feed.dart';
import 'package:jplayer/src/core/diagnostics/diagnostics.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';

const castSinkMimeTypes = <String>{
  'audio/mpeg',
  'audio/mp4',
  'audio/aac',
  'audio/flac',
  'audio/wav',
  'audio/ogg',
};

class CastSessionFailure implements Exception {
  const CastSessionFailure(this.deviceName);

  final String deviceName;

  @override
  String toString() => 'could not start a Cast session with $deviceName';
}

class CastPlaybackTarget implements PlaybackTarget {
  CastPlaybackTarget(
    this.device, {
    this.diagnostics = const Diagnostics(),
    this.attemptTimeout = _attemptTimeout,
    this.pollInterval = _pollInterval,
    this.discoverySettle = _discoverySettle,
    GoogleCastRemoteMediaClientPlatformInterface? client,
    GoogleCastSessionManagerPlatformInterface? sessions,
    GoogleCastDiscoveryManagerPlatformInterface? discovery,
    CastMediaFeed? feed,
  }) : _injectedClient = client,
       _injectedSessions = sessions,
       _discovery = discovery,
       _injectedFeed = feed;

  static const _connectTimeout = Duration(seconds: 20);
  static const _attemptTimeout = Duration(seconds: 6);
  static const _routeTimeout = Duration(seconds: 4);
  static const _connectRetryDelay = Duration(milliseconds: 500);
  static const _discoverySettle = Duration(milliseconds: 300);
  static const _pollInterval = Duration(milliseconds: 200);
  static const _connectAttempts = 3;
  static const _restartThreshold = Duration(seconds: 3);

  final GoogleCastDevice device;
  final Diagnostics diagnostics;
  final Duration attemptTimeout;
  final Duration pollInterval;
  final Duration discoverySettle;

  final _controller = StreamController<TargetPlaybackState>.broadcast();
  final _tracks = <TargetTrack>[];
  final _subscriptions = <StreamSubscription<Object?>>[];

  var _itemIds = <int>[];
  var _index = 0;
  Duration _position = Duration.zero;
  var _disposed = false;
  var _loaded = false;
  var _startedDiscovery = false;
  var _sawSession = false;
  var _pauseWhenReady = false;
  TargetPlaybackState _state = TargetPlaybackState.idle;
  CastReceiverStatus? _status;
  Future<void>? _session;

  final GoogleCastRemoteMediaClientPlatformInterface? _injectedClient;
  final GoogleCastSessionManagerPlatformInterface? _injectedSessions;
  final GoogleCastDiscoveryManagerPlatformInterface? _discovery;
  final CastMediaFeed? _injectedFeed;

  CastMediaFeed get _feed => _injectedFeed ?? CastChannelFeed.instance;

  GoogleCastRemoteMediaClientPlatformInterface get _client =>
      _injectedClient ?? GoogleCastRemoteMediaClient.instance;

  GoogleCastSessionManagerPlatformInterface get _sessions =>
      _injectedSessions ?? GoogleCastSessionManager.instance;

  @override
  String get id => 'cast:${device.deviceID}';

  @override
  String get name => device.friendlyName;

  @override
  PlaybackTargetKind get kind => PlaybackTargetKind.cast;

  @override
  StreamTargetProfile get streamProfile =>
      StreamTargetProfile.renderer(sinkMimeTypes: castSinkMimeTypes);

  @override
  bool get supportsLocalFiles => false;

  @override
  TargetPlaybackState get state => _state;

  @override
  Stream<TargetPlaybackState> get stateStream => _controller.stream;

  @override
  Future<void> load(
    List<TargetTrack> tracks, {
    required int initialIndex,
    required Duration initialPosition,
    required bool autoPlay,
  }) async {
    _tracks
      ..clear()
      ..addAll(tracks);
    _itemIds = const [];
    _status = null;
    _loaded = false;
    _index = tracks.isEmpty ? 0 : initialIndex.clamp(0, tracks.length - 1);
    _position = initialPosition;
    _pauseWhenReady = !autoPlay;

    _emit(
      status: autoPlay ? PlaybackStatus.buffering : PlaybackStatus.paused,
      position: initialPosition,
      duration: _currentTrack?.duration,
    );

    try {
      await _ensureSession();
      await _client.queueLoadItems(
        [for (final track in tracks) _queueItem(track)],
        options: GoogleCastQueueLoadOptions(
          startIndex: _index,
          playPosition: initialPosition,
        ),
      );
    } on Object catch (error, stackTrace) {
      unawaited(
        diagnostics.capture(
          error,
          stackTrace: stackTrace,
          operation: 'cast.queue.load',
          tags: _deviceTags,
          extra: {'tracks': tracks.length, ..._streamInfo(_currentTrack)},
        ),
      );
      _emit(status: PlaybackStatus.error);
      return;
    }

    _loaded = true;
    diagnostics.trail(
      'cast queue of ${tracks.length} handed to $name at $_index '
      'autoPlay=$autoPlay',
      category: 'cast',
    );
    if (!autoPlay) await _client.pause();
  }

  Future<void> _ensureSession() async {
    try {
      await (_session ??= _openSession());
    } on Object {
      _session = null;
      rethrow;
    }
  }

  Future<void> _openSession() async {
    final discovery = _discovery ?? GoogleCastDiscoveryManager.instance;
    final watch = _sessions.currentSessionStream.listen(_trailSession);
    final deadline = DateTime.now().add(_connectTimeout);
    try {
      if (!_connectedToDevice(_sessions.currentSession)) {
        diagnostics.trail(
          'cast connecting to $name (${device.deviceID})',
          category: 'cast',
        );
        if (!_startedDiscovery) {
          _startedDiscovery = true;
          await discovery.startDiscovery();
          await Future<void>.delayed(discoverySettle);
        }

        for (var attempt = 1; attempt <= _connectAttempts; attempt++) {
          if (_disposed) return;
          await _waitForRoute(discovery);
          await _selectRoute();
          if (await _connectedWithin(attemptTimeout)) break;
          if (_disposed || DateTime.now().isAfter(deadline)) break;
          diagnostics.trail(
            'cast attempt $attempt to $name went unanswered',
            category: 'cast',
          );
        }
      }

      if (_disposed) return;
      if (!_connectedToDevice(_sessions.currentSession)) {
        throw CastSessionFailure(name);
      }
    } finally {
      unawaited(watch.cancel());
    }

    _sawSession = true;
    _listen();
  }

  Future<bool> _connectedWithin(Duration limit) async {
    final deadline = DateTime.now().add(limit);
    while (!_connectedToDevice(_sessions.currentSession)) {
      if (_disposed || DateTime.now().isAfter(deadline)) return false;
      await Future<void>.delayed(pollInterval);
    }
    return true;
  }

  Future<void> _waitForRoute(
    GoogleCastDiscoveryManagerPlatformInterface discovery,
  ) async {
    if (_listed(discovery.devices)) return;
    await discovery.devicesStream
        .firstWhere(_listed)
        .timeout(_routeTimeout, onTimeout: () => const []);
  }

  bool _listed(List<GoogleCastDevice> devices) =>
      devices.any((found) => found.deviceID == device.deviceID);

  Future<void> _selectRoute() async {
    final current = _sessions.currentSession;
    if (_liveSession(current)) return;
    if (current != null && _connectingOrConnected(current)) {
      await _sessions.endSessionAndStopCasting();
      await Future<void>.delayed(_connectRetryDelay);
    }
    await _sessions.startSessionWithDevice(device);
  }

  void _trailSession(GoogleCastSession? session) => diagnostics.trail(
    session == null
        ? 'cast session gone'
        : 'cast session ${session.connectionState.name} '
              'device=${session.device?.deviceID ?? 'none'} '
              'id=${session.sessionID ?? 'none'}',
    category: 'cast',
  );

  bool _ourSession(GoogleCastSession? session) =>
      session != null &&
      (session.device == null || session.device!.deviceID == device.deviceID);

  bool _liveSession(GoogleCastSession? session) =>
      _ourSession(session) && _connectingOrConnected(session!);

  bool _connectingOrConnected(GoogleCastSession session) => const {
    GoogleCastConnectState.connected,
    GoogleCastConnectState.connecting,
  }.contains(session.connectionState);

  bool _connectedToDevice(GoogleCastSession? session) =>
      _ourSession(session) &&
      session!.connectionState == GoogleCastConnectState.connected;

  void _listen() {
    if (_subscriptions.isNotEmpty) return;
    _subscriptions.addAll([
      _feed.statuses.listen(_onStatus),
      _feed.positions.listen(_onPosition),
      _feed.queue.listen(_onQueueItems),
      _sessions.currentSessionStream.listen(_onSession),
    ]);
  }

  GoogleCastQueueItem _queueItem(TargetTrack track) {
    final artUri = track.artUri;
    return GoogleCastQueueItem(
      mediaInformation: GoogleCastMediaInformation(
        contentId: track.itemId,
        contentUrl: track.uri,
        contentType: track.mimeType,
        streamType: CastMediaStreamType.buffered,
        duration: track.duration,
        metadata: GoogleCastMusicMediaMetadata(
          title: track.title,
          artist: track.artist,
          albumArtist: track.artist,
          albumName: track.album,
          images: artUri == null ? null : [GoogleCastImage(url: artUri)],
        ),
      ),
    );
  }

  void _onStatus(CastReceiverStatus status) {
    if (_disposed || !_loaded) return;
    _status = status;

    final index = _indexOfCurrentItem(status);
    if (index != null) _index = index;

    if (_pauseWhenReady && status.status == PlaybackStatus.playing) {
      _pauseWhenReady = false;
      unawaited(_client.pause());
      return;
    }

    _emit(
      status: status.status,
      duration: status.duration ?? _currentTrack?.duration,
      completed: _finishedQueue(status),
    );
  }

  void _onPosition(Duration position) {
    if (_disposed || !_loaded) return;
    _position = position;
    _emit();
  }

  void _onQueueItems(List<CastQueueEntry> items) {
    if (_disposed || !_loaded) return;

    final ids = [for (final item in items) item.itemId];
    final contents = [for (final item in items) item.contentId];
    _itemIds = _mirrorsQueue(contents) ? ids : const [];

    final status = _status;
    final index = status != null ? _indexOfCurrentItem(status) : null;
    if (index == null || index == _index) return;
    _index = index;
    _emit();
  }

  void _onSession(GoogleCastSession? session) {
    if (_disposed || !_sawSession) return;
    if (_ourSession(session) &&
        session!.connectionState != GoogleCastConnectState.disconnected) {
      return;
    }
    if (session == null && _sessions.currentSession != null) return;
    diagnostics.trail(
      'cast session with $name ended from the device side',
      category: 'cast',
    );
    _emit(status: PlaybackStatus.error);
  }

  bool _mirrorsQueue(List<String> contents) {
    if (contents.length != _tracks.length) return false;
    for (var index = 0; index < contents.length; index++) {
      if (contents[index] != _tracks[index].itemId) return false;
    }
    return true;
  }

  int? _indexOfCurrentItem(CastReceiverStatus status) {
    final itemId = status.itemId;
    if (itemId != null) {
      final index = _itemIds.indexOf(itemId);
      if (index >= 0) return index;
    }
    final contentId = status.contentId;
    if (contentId == null || contentId.isEmpty) return null;
    final index = _tracks.indexWhere((track) => track.itemId == contentId);
    return index >= 0 ? index : null;
  }

  bool _finishedQueue(CastReceiverStatus status) =>
      status.finished && _index >= _tracks.length - 1;

  @override
  Future<void> play() async {
    _pauseWhenReady = false;
    await _client.play();
  }

  @override
  Future<void> pause() async {
    _pauseWhenReady = false;
    await _client.pause();
  }

  @override
  Future<void> stop() async {
    _pauseWhenReady = false;
    await _client.stop();
    _position = Duration.zero;
    _emit(status: PlaybackStatus.stopped, position: Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    await _client.seek(GoogleCastMediaSeekOption(position: position));
    _position = position;
    _emit();
  }

  @override
  Future<void> skipTo(int index) async {
    final itemId = _itemIdAt(index);
    if (itemId == null) {
      await load(
        [..._tracks],
        initialIndex: index,
        initialPosition: Duration.zero,
        autoPlay: _state.status.isPlaying,
      );
      return;
    }
    _index = index;
    await _client.queueJumpToItemWithId(itemId);
  }

  @override
  Future<void> move(int from, int to) async {
    final itemId = _itemIdAt(from);
    if (itemId == null || _itemIdAt(to) == null) return;

    await _client.queueReorderItems(
      itemsIds: [itemId],
      beforeItemWithId: _itemIdAt(to > from ? to + 1 : to),
    );

    _itemIds = [..._itemIds]
      ..removeAt(from)
      ..insert(to, itemId);
    if (from < _tracks.length && to < _tracks.length) {
      _tracks.insert(to, _tracks.removeAt(from));
    }
  }

  @override
  Future<void> remove(int index) async {
    final itemId = _itemIdAt(index);
    if (itemId == null) return;

    await _client.queueRemoveItemsWithIds([itemId]);

    _itemIds = [..._itemIds]..removeAt(index);
    if (index < _tracks.length) _tracks.removeAt(index);
  }

  @override
  Future<void> insert(
    int index,
    TargetTrack track, {
    bool playNext = false,
  }) async {
    await _client.queueInsertItems(
      [_queueItem(track)],
      beforeItemWithId: _itemIdAt(index),
    );
    _tracks.insert(index.clamp(0, _tracks.length), track);
  }

  @override
  Future<void> reorder(
    List<TargetTrack> tracks, {
    required List<int> order,
    required int currentIndex,
  }) async {
    if (order.length != _itemIds.length) {
      diagnostics.trail(
        'cast queue is out of step; leaving its order alone',
        category: 'cast',
      );
      return;
    }

    final ids = [for (final from in order) _itemIds[from]];
    await _client.queueReorderItems(itemsIds: ids, beforeItemWithId: null);

    _itemIds = ids;
    _index = currentIndex;
    _tracks
      ..clear()
      ..addAll(tracks);
  }

  @override
  Future<void> seekToNext() => _client.queueNextItem();

  @override
  Future<void> seekToPrevious() async {
    if (_index > 0 && _position <= _restartThreshold) {
      await _client.queuePrevItem();
      return;
    }
    await seek(Duration.zero);
  }

  @override
  Future<void> setVolume(double level) async {
    try {
      await _ensureSession();
    } on Object {
      return;
    }
    _sessions.setDeviceVolume(level);
  }

  @override
  Future<double?> currentVolume() async {
    try {
      await _ensureSession();
    } on Object {
      return null;
    }
    return _sessions.currentSession?.currentDeviceVolume;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _loaded = false;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    if (_startedDiscovery) {
      _startedDiscovery = false;
      unawaited(
        (_discovery ?? GoogleCastDiscoveryManager.instance).stopDiscovery(),
      );
    }
    try {
      await _sessions.endSessionAndStopCasting();
    } on Object catch (error) {
      diagnostics.trail(
        'ending the Cast session failed: $error',
        category: 'cast',
      );
    }
    await _controller.close();
  }

  int? _itemIdAt(int index) =>
      index >= 0 && index < _itemIds.length ? _itemIds[index] : null;

  TargetTrack? get _currentTrack => _tracks.elementAtOrNull(_index);

  Map<String, String> get _deviceTags => {
    'cast.model': device.modelName ?? 'unknown',
    'cast.version': device.deviceVersion,
  };

  Map<String, Object?> _streamInfo(TargetTrack? track) => {
    if (track != null) ...{
      'mimeType': track.mimeType,
      'transcoded': track.transcoded,
    },
  };

  void _emit({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    bool completed = false,
  }) {
    if (_disposed || _controller.isClosed) return;
    _state = TargetPlaybackState(
      status: status ?? _state.status,
      position: position ?? _position,
      currentIndex: _index,
      duration: duration ?? _state.duration,
      completed: completed,
    );
    _controller.add(_state);
  }
}
