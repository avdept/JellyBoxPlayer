import 'dart:async';

import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/cast/cast_discovery.dart';
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
    this.sessionGrace = _sessionGrace,
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
  static const _sessionGrace = Duration(seconds: 20);

  final GoogleCastDevice device;
  final Diagnostics diagnostics;
  final Duration attemptTimeout;
  final Duration pollInterval;
  final Duration discoverySettle;
  final Duration sessionGrace;

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
  double? _pendingVolume;
  Timer? _sessionLoss;
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

    _emit(
      status: autoPlay ? PlaybackStatus.buffering : PlaybackStatus.paused,
      position: initialPosition,
      duration: _currentTrack?.duration,
    );

    try {
      await _ensureSession();
      final pendingVolume = _pendingVolume;
      if (pendingVolume != null) {
        _pendingVolume = null;
        _sessions.setDeviceVolume(pendingVolume);
      }
      await _client.queueLoadItems(
        [for (final track in tracks) _queueItem(track)],
        options: GoogleCastQueueLoadOptions(
          startIndex: _index,
          playPosition: initialPosition,
          autoPlay: autoPlay,
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
          await CastDiscovery.of(discovery).hold();
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

    _itemIds = _mirrorsQueue(items)
        ? [for (final item in items) item.itemId]
        : const [];

    final status = _status;
    final index = status != null ? _indexOfCurrentItem(status) : null;
    if (index == null || index == _index) return;
    _index = index;
    _emit();
  }

  void _onSession(GoogleCastSession? session) {
    if (_disposed || !_sawSession) return;
    if (_liveSession(session)) {
      if (_sessionLoss != null) {
        diagnostics.trail('cast session with $name is back', category: 'cast');
      }
      _sessionLoss?.cancel();
      _sessionLoss = null;
      return;
    }
    if (_ourSession(session) &&
        session!.connectionState == GoogleCastConnectState.disconnecting) {
      return;
    }
    if (_sessionLoss != null) return;
    diagnostics.trail(
      'cast session with $name dropped; waiting for it to resume',
      category: 'cast',
    );
    _sessionLoss = Timer(sessionGrace, () {
      _sessionLoss = null;
      if (_disposed) return;
      diagnostics.trail(
        'cast session with $name did not come back',
        category: 'cast',
      );
      _emit(status: PlaybackStatus.error);
    });
  }

  bool _mirrorsQueue(List<CastQueueEntry> items) {
    if (items.length != _tracks.length) return false;
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (!_matches(_tracks[index], item.contentId, item.contentUrl)) {
        return false;
      }
    }
    return true;
  }

  bool _matches(TargetTrack track, String? contentId, String? contentUrl) {
    if (contentId != null && contentId.isNotEmpty) {
      return track.itemId == contentId || track.uri.toString() == contentId;
    }
    return contentUrl != null && track.uri.toString() == contentUrl;
  }

  int? _indexOfCurrentItem(CastReceiverStatus status) {
    final itemId = status.itemId;
    if (itemId != null) {
      final index = _itemIds.indexOf(itemId);
      if (index >= 0) return index;
    }
    final index = _tracks.indexWhere(
      (track) => _matches(track, status.contentId, status.contentUrl),
    );
    return index >= 0 ? index : null;
  }

  Future<void> _reload({Duration? position}) => load(
    [..._tracks],
    initialIndex: _index,
    initialPosition: position ?? _position,
    autoPlay: _state.status.isPlaying,
  );

  bool _finishedQueue(CastReceiverStatus status) =>
      status.finished && _index >= _tracks.length - 1;

  @override
  Future<void> play() => _client.play();

  @override
  Future<void> pause() => _client.pause();

  @override
  Future<void> stop() async {
    await _client.stop();
    _position = Duration.zero;
    _emit(status: PlaybackStatus.stopped, position: Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    await _client.seek(
      GoogleCastMediaSeekOption(
        position: position,
        resumeState: GoogleCastMediaResumeState.unchanged,
      ),
    );
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
    if (from < 0 || to < 0 || from >= _tracks.length || to >= _tracks.length) {
      return;
    }
    final itemId = _itemIdAt(from);
    final inStep = itemId != null && _itemIdAt(to) != null;

    _tracks.insert(to, _tracks.removeAt(from));
    if (_index == from) {
      _index = to;
    } else if (from < _index && to >= _index) {
      _index--;
    } else if (from > _index && to <= _index) {
      _index++;
    }

    if (!inStep) {
      await _reload();
      return;
    }
    final before = to > from ? to + 1 : to;
    await _client.queueReorderItems(
      itemsIds: [itemId],
      beforeItemWithId: _itemIdAt(before),
    );
    _itemIds = [..._itemIds]
      ..removeAt(from)
      ..insert(to, itemId);
  }

  @override
  Future<void> remove(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    final itemId = _itemIdAt(index);
    final wasCurrent = index == _index;

    _tracks.removeAt(index);
    if (index < _index) _index--;
    if (_tracks.isNotEmpty) _index = _index.clamp(0, _tracks.length - 1);

    if (itemId == null) {
      await _reload(position: wasCurrent ? Duration.zero : null);
      return;
    }
    await _client.queueRemoveItemsWithIds([itemId]);
    _itemIds = [..._itemIds]..removeAt(index);
  }

  @override
  Future<void> insert(
    int index,
    TargetTrack track, {
    bool playNext = false,
  }) async {
    final at = index.clamp(0, _tracks.length);
    final inStep = _itemIds.length == _tracks.length;
    final beforeId = _itemIdAt(at);

    _tracks.insert(at, track);
    if (at <= _index) _index++;

    if (!inStep) {
      await _reload();
      return;
    }
    await _client.queueInsertItems([
      _queueItem(track),
    ], beforeItemWithId: beforeId);
  }

  @override
  Future<void> replaceAroundCurrent(
    int currentIndex,
    List<TargetTrack> upcoming,
  ) async {
    if (currentIndex < 0 || currentIndex >= _tracks.length) return;
    final currentId = _itemIdAt(currentIndex);

    final current = _tracks[currentIndex];
    _index = 0;
    _tracks
      ..clear()
      ..add(current)
      ..addAll(upcoming);
    _emit(duration: current.duration);

    if (currentId == null) {
      await _reload();
      return;
    }

    final others = [
      for (final id in _itemIds)
        if (id != currentId) id,
    ];
    if (others.isNotEmpty) await _client.queueRemoveItemsWithIds(others);
    _itemIds = [currentId];

    if (upcoming.isEmpty) return;
    await _client.queueInsertItems([
      for (final track in upcoming) _queueItem(track),
    ]);
  }

  @override
  Future<void> reorder(
    List<TargetTrack> tracks, {
    required List<int> order,
    required int currentIndex,
  }) async {
    final inStep = order.length == _itemIds.length;
    final ids = inStep ? [for (final from in order) _itemIds[from]] : null;

    _index = currentIndex;
    _tracks
      ..clear()
      ..addAll(tracks);

    if (ids == null) {
      await _reload();
      return;
    }
    await _client.queueReorderItems(itemsIds: ids, beforeItemWithId: null);
    _itemIds = ids;
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
    if (_session == null) {
      _pendingVolume = level;
      return;
    }
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
    _sessionLoss?.cancel();
    _sessionLoss = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    if (_startedDiscovery) {
      _startedDiscovery = false;
      unawaited(
        CastDiscovery.of(
          _discovery ?? GoogleCastDiscoveryManager.instance,
        ).release(),
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
