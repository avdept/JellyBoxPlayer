import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/_remote_media_client/remote_media_client_platform.dart';
import 'package:flutter_chrome_cast/entities/cast_media_status.dart';
import 'package:flutter_chrome_cast/entities/load_options.dart';
import 'package:flutter_chrome_cast/entities/media_seek_option.dart';
import 'package:flutter_chrome_cast/entities/queue_item.dart';
import 'package:flutter_chrome_cast/entities/media_information.dart';
import 'package:flutter_chrome_cast/models/ios/ios_cast_queue_item.dart';
import 'package:flutter_chrome_cast/models/ios/ios_media_status.dart';
import 'package:rxdart/rxdart.dart';

/// iOS-specific implementation of Google Cast remote media client functionality.
class GoogleCastRemoteMediaClientIOSMethodChannel
    implements GoogleCastRemoteMediaClientPlatformInterface {
  /// Creates a new iOS remote media client method channel.
  GoogleCastRemoteMediaClientIOSMethodChannel() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  final _channel = const MethodChannel('google_cast.remote_media_client');
  bool _queueHasNextItem = false;

  final _mediaStatusStreamController = BehaviorSubject<GoggleCastMediaStatus?>()
    ..add(null);

  final _playerPositionStreamController = BehaviorSubject<Duration>()
    ..add(Duration.zero);

  // After `loadMedia`, the native `GCKRemoteMediaClient.approximateStreamPosition()`
  // keeps returning the previous content's last known position until the SDK
  // applies the new mediaStatus on the device. As a result, the first few
  // `onUpdatePlayerPosition` ticks emitted by the iOS side leak stale values
  // from the previous content (e.g. 0:01:10 right after loading a new content
  // whose intended start is 0:02:07). We block such stale ticks at the Dart
  // boundary until BOTH conditions are met:
  //   1. The mediaSessionID has changed compared to the one observed at the
  //      moment of `loadMedia` (the SDK applied the new stream).
  //   2. The reported position has converged to the expected start position
  //      within a small tolerance.
  // A safety timeout releases the guard if convergence never happens (e.g.
  // playback was stopped/seeked before reaching the expected position).
  Duration? _pendingLoadExpectedPosition;
  int? _pendingLoadPreviousMediaSessionId;
  Timer? _pendingLoadGuardTimer;
  static const _pendingLoadGuardTimeout = Duration(seconds: 10);
  static const _pendingLoadGuardTolerance = Duration(seconds: 5);

  final _queueItemsStreamController =
      BehaviorSubject<List<GoogleCastQueueItem>>()..add([]);

  @override
  GoggleCastMediaStatus? get mediaStatus => _mediaStatusStreamController.value;

  @override
  Stream<GoggleCastMediaStatus?> get mediaStatusStream =>
      _mediaStatusStreamController.stream;

  @override
  Duration get playerPosition => _playerPositionStreamController.value;

  @override
  Stream<Duration> get playerPositionStream =>
      _playerPositionStreamController.stream;

  @override
  List<GoogleCastQueueItem> get queueItems => _queueItemsStreamController.value;

  @override
  Stream<List<GoogleCastQueueItem>> get queueItemsStream =>
      _queueItemsStreamController.stream;

  @override
  bool get queueHasNextItem => _queueHasNextItem;

  @override
  bool get queueHasPreviousItem {
    final index = queueItems
        .map((e) => e.itemId)
        .toList()
        .lastIndexOf(mediaStatus?.currentItemId);
    return index > 0;
  }

  @override
  Future<void> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
    Map<String, dynamic>? customData,
  }) async {
    // Arm the stale-position guard BEFORE invoking the platform channel so
    // that any position tick emitted right after `loadMedia` is filtered out.
    _armPendingLoadGuard(playPosition);
    _channel.invokeMethod(
        'loadMedia',
        mediaInfo.toMap()
          ..addAll(
            {
              'autoPlay': autoPlay,
              'playPosition': playPosition.inSeconds,
              'playbackRate': playbackRate,
              'activeTrackIds': activeTrackIds,
              'credentials': credentials,
              'credentialsType': credentialsType,
              'customData': customData,
            }..removeWhere((key, value) => value == null),
          ));
  }

  @override
  Future<void> pause() async {
    await _channel.invokeMethod('pause');
  }

  @override
  Future<void> play() async {
    await _channel.invokeMethod('play');
  }

  @override
  Future<void> setActiveTrackIDs(List<int> activeTrackIDs) async {
    await _channel.invokeMethod('setActiveTrackIDs', activeTrackIDs.toList());
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    await _channel.invokeMethod('setPlaybackRate', rate);
  }

  @override
  Future<void> setTextTrackStyle(TextTrackStyle textTrackStyle) async {
    await _channel.invokeMethod('setTextTrackStyle', textTrackStyle.toMap());
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  @override
  Future<void> seek(GoogleCastMediaSeekOption option) async {
    await _channel.invokeMethod('seek', option.toMap());
  }

  @override
  Future<void> queueNextItem() async {
    await _channel.invokeMethod('queueNextItem');
  }

  @override
  Future<void> queuePrevItem() async {
    _channel.invokeMethod('queuePrevItem');
  }

// MARK: - MethodCallHandler
  Future _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case "onUpdateMediaStatus":
        return await _onUpdateMediaStatus(call.arguments);
      case "onUpdatePlayerPosition":
        return await _onUpdatePlayerPosition(call.arguments);
      case "updateQueueItems":
        return await _updateQueueItems(call.arguments);
      default:
    }
  }

  Future _onUpdatePlayerPosition(int milliseconds) async {
    final duration = Duration(milliseconds: milliseconds);
    final expected = _pendingLoadExpectedPosition;
    if (expected != null) {
      final currentSessionId =
          _mediaStatusStreamController.value?.mediaSessionID;
      // `mediaSessionID` is non-null `int` (defaults to 0 when no status yet).
      // Treat 0 and the previously observed id as "not changed yet".
      final sessionChanged = currentSessionId != null &&
          currentSessionId != 0 &&
          currentSessionId != _pendingLoadPreviousMediaSessionId;
      final converged =
          (duration - expected).abs() <= _pendingLoadGuardTolerance;
      if (!sessionChanged || !converged) {
        return;
      }
      _releasePendingLoadGuard();
    }
    _playerPositionStreamController.add(duration);
  }

  void _armPendingLoadGuard(Duration expectedPosition) {
    _pendingLoadExpectedPosition = expectedPosition;
    _pendingLoadPreviousMediaSessionId =
        _mediaStatusStreamController.value?.mediaSessionID;
    // Overwrite the BehaviorSubject's cached value so that any consumer that
    // reads `playerPosition` synchronously (e.g. polls it via a periodic
    // timer) sees the expected start of the new content instead of the
    // previous content's last reported position. Without this, even though
    // `onUpdatePlayerPosition` ticks are filtered, the stale cached value
    // leaks into the app right after `loadMedia`.
    _playerPositionStreamController.add(expectedPosition);
    _pendingLoadGuardTimer?.cancel();
    _pendingLoadGuardTimer = Timer(_pendingLoadGuardTimeout, () {
      _releasePendingLoadGuard();
    });
  }

  void _releasePendingLoadGuard() {
    _pendingLoadExpectedPosition = null;
    _pendingLoadPreviousMediaSessionId = null;
    _pendingLoadGuardTimer?.cancel();
    _pendingLoadGuardTimer = null;
  }

  /// Recursively converts a `Map<Object?, Object?>` to `Map<String, dynamic>`.
  ///
  /// This is necessary because the platform channel may return nested maps
  /// as `Map<Object?, Object?>`, which needs to be converted for proper parsing.
  dynamic _convertToStringDynamicMap(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, val) => MapEntry(key.toString(), _convertToStringDynamicMap(val)),
      );
    } else if (value is List) {
      return value.map((e) => _convertToStringDynamicMap(e)).toList();
    }
    return value;
  }

  FutureOr<void> _onUpdateMediaStatus(dynamic arguments) {
    if (arguments != null) {
      try {
        arguments =
            _convertToStringDynamicMap(arguments) as Map<String, dynamic>;
        debugPrint(
            '[Flutter] _onUpdateMediaStatus received: playerState=${arguments['playerState']}');
        final mediaStatus = GoogleCastIOSMediaStatus.fromMap(arguments);
        debugPrint(
            '[Flutter] _onUpdateMediaStatus parsed: playerState=${mediaStatus.playerState}');
        _queueHasNextItem = arguments["queueHasNextItem"];
        _mediaStatusStreamController.add(mediaStatus);
      } catch (e) {
        debugPrint('[Flutter] _onUpdateMediaStatus error: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> queueLoadItems(
    List<GoogleCastQueueItem> queueItems, {
    GoogleCastQueueLoadOptions? options,
  }) async {
    _channel.invokeMethod(
      'queueLoadItems',
      {
        'items': queueItems.map((item) => item.toMap()).toList(),
        if (options != null) 'options': options.toMap(),
      },
    );
  }

  @override
  Future<void> queueInsertItems(List<GoogleCastQueueItem> items,
      {int? beforeItemWithId}) async {
    _channel.invokeMethod('queueInsertItems', {
      'items': items.map((item) => item.toMap()).toList(),
      'beforeItemWithId': beforeItemWithId,
    });
  }

  @override
  Future<void> queueInsertItemAndPlay(
    GoogleCastQueueItem item, {
    required int beforeItemWithId,
  }) async {
    assert(beforeItemWithId >= 0, 'beforeItemWithId must be greater than 0');
    _channel.invokeMethod('queueInsertItemAndPlay', {
      'item': item.toMap(),
      'beforeItemWithId': beforeItemWithId,
    });
    return;
  }

  @override
  Future<void> queueJumpToItemWithId(int itemId) async {
    _channel.invokeMethod('queueJumpToItemWithId', itemId);
  }

  @override
  Future<void> queueRemoveItemsWithIds(List<int> itemIds) async {
    _channel.invokeMethod('queueRemoveItemsWithIds', itemIds);
  }

  FutureOr<void> _updateQueueItems(dynamic arguments) async {
    final items = List.from(arguments ?? []);
    final queueItems = items
        .map((item) =>
            GoogleCastQueueItemIOS.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    _queueItemsStreamController.add(queueItems);
  }

  @override
  Future<void> queueReorderItems(
      {required List<int> itemsIds, required int? beforeItemWithId}) async {
    _channel.invokeMethod(
      'queueReorderItems',
      {
        'itemsIds': itemsIds,
        'beforeItemWithId': beforeItemWithId,
      },
    );
  }
}
