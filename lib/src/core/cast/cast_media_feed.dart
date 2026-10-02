import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:jplayer/src/core/enums/enums.dart';

class CastReceiverStatus {
  const CastReceiverStatus({
    required this.status,
    this.mediaSessionId,
    this.itemId,
    this.contentId,
    this.contentUrl,
    this.duration,
    this.finished = false,
    this.failed = false,
  });

  final PlaybackStatus status;
  final int? mediaSessionId;
  final int? itemId;
  final String? contentId;
  final String? contentUrl;

  bool get hasMedia =>
      (contentId?.isNotEmpty ?? false) || (contentUrl?.isNotEmpty ?? false);
  final Duration? duration;
  final bool finished;
  final bool failed;
}

class CastQueueEntry {
  const CastQueueEntry({
    required this.itemId,
    this.contentId,
    this.contentUrl,
  });

  final int itemId;
  final String? contentId;
  final String? contentUrl;
}

abstract class CastMediaFeed {
  Stream<CastReceiverStatus> get statuses;

  Stream<List<CastQueueEntry>> get queue;

  Stream<Duration> get positions;
}

const _iosIdle = 1;
const _iosPlaying = 2;
const _iosPaused = 3;
const _iosBuffering = 4;
const _iosLoading = 5;
const _iosIdleFinished = 1;
const _iosIdleCancelled = 2;
const _iosIdleInterrupted = 3;
const _iosIdleError = 4;

class CastChannelFeed implements CastMediaFeed {
  CastChannelFeed._() {
    claimChannel();
  }

  void claimChannel() {
    _androidChannel.setMethodCallHandler(_onCall);
    _iosChannel.setMethodCallHandler(_onCall);
  }

  static final CastChannelFeed instance = CastChannelFeed._();

  static const _androidChannel = MethodChannel(
    'com.felnanuke.google_cast.remote_media_client',
  );
  static const _iosChannel = MethodChannel('google_cast.remote_media_client');

  final _statuses = StreamController<CastReceiverStatus>.broadcast();
  final _queue = StreamController<List<CastQueueEntry>>.broadcast();
  final _positions = StreamController<Duration>.broadcast();

  @override
  Stream<CastReceiverStatus> get statuses => _statuses.stream;

  @override
  Stream<List<CastQueueEntry>> get queue => _queue.stream;

  @override
  Stream<Duration> get positions => _positions.stream;

  Future<void> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'onMediaStatusChanged':
        _onStatus(call.arguments);
      case 'onQueueStatusChanged':
        _onQueue(call.arguments);
      case 'onPlayerPositionChanged':
        _onPosition(call.arguments);
      case 'onUpdateMediaStatus':
        _onIosStatus(call.arguments);
      case 'updateQueueItems':
        _onIosQueue(call.arguments);
      case 'onUpdatePlayerPosition':
        _onIosPosition(call.arguments);
    }
  }

  void _onStatus(Object? arguments) {
    if (arguments is! String) return;
    final decoded = _decode(arguments);
    if (decoded == null) return;

    final state = '${decoded['playerState']}'.toUpperCase();
    final idleReason = '${decoded['idleReason']}'.toUpperCase();
    final media = decoded['media'];
    final duration = media is Map ? media['duration'] : null;

    _statuses.add(
      CastReceiverStatus(
        status: switch (state) {
          'PLAYING' => PlaybackStatus.playing,
          'PAUSED' => PlaybackStatus.paused,
          'BUFFERING' || 'LOADING' => PlaybackStatus.buffering,
          'IDLE' when idleReason == 'ERROR' => PlaybackStatus.error,
          'IDLE'
              when idleReason == 'CANCELLED' || idleReason == 'INTERRUPTED' =>
            PlaybackStatus.paused,
          _ => PlaybackStatus.stopped,
        },
        mediaSessionId: (decoded['mediaSessionId'] as num?)?.toInt(),
        itemId: (decoded['currentItemId'] as num?)?.toInt(),
        contentId: media is Map ? media['contentId'] as String? : null,
        contentUrl: media is Map ? media['contentUrl'] as String? : null,
        duration: duration is num
            ? Duration(milliseconds: (duration * 1000).round())
            : null,
        finished: state == 'IDLE' && idleReason == 'FINISHED',
        failed: state == 'IDLE' && idleReason == 'ERROR',
      ),
    );
  }

  void _onQueue(Object? arguments) {
    if (arguments is! List) {
      _queue.add(const []);
      return;
    }

    final entries = <CastQueueEntry>[];
    for (final raw in arguments) {
      final item = raw is String ? _decode(raw) : null;
      final itemId = (item?['itemId'] as num?)?.toInt();
      final media = item?['media'];
      final contentId = media is Map ? media['contentId'] as String? : null;
      final contentUrl = media is Map ? media['contentUrl'] as String? : null;
      if (itemId == null || (contentId == null && contentUrl == null)) continue;
      entries.add(
        CastQueueEntry(
          itemId: itemId,
          contentId: contentId,
          contentUrl: contentUrl,
        ),
      );
    }
    _queue.add(entries);
  }

  void _onPosition(Object? arguments) {
    if (arguments is! Map) return;
    final progress = arguments['progress'];
    if (progress is! num) return;
    _positions.add(Duration(milliseconds: progress.toInt()));
  }

  void _onIosStatus(Object? arguments) {
    if (arguments is! Map) return;

    final state = arguments['playerState'];
    final idleReason = arguments['idleReason'];
    final media = arguments['mediaInformation'];
    final duration = media is Map ? media['duration'] : null;
    final itemId = (arguments['currentItemId'] as num?)?.toInt();
    final idle = state == _iosIdle;

    _statuses.add(
      CastReceiverStatus(
        status: switch (state) {
          _iosPlaying => PlaybackStatus.playing,
          _iosPaused => PlaybackStatus.paused,
          _iosBuffering || _iosLoading => PlaybackStatus.buffering,
          _iosIdle when idleReason == _iosIdleError => PlaybackStatus.error,
          _iosIdle
              when idleReason == _iosIdleCancelled ||
                  idleReason == _iosIdleInterrupted =>
            PlaybackStatus.paused,
          _ => PlaybackStatus.stopped,
        },
        mediaSessionId: (arguments['mediaSessionID'] as num?)?.toInt(),
        itemId: itemId == null || itemId == 0 ? null : itemId,
        contentId: media is Map ? media['contentID'] as String? : null,
        contentUrl: media is Map ? media['contentURL'] as String? : null,
        duration: duration is num && duration > 0
            ? Duration(milliseconds: (duration * 1000).round())
            : null,
        finished: idle && idleReason == _iosIdleFinished,
        failed: idle && idleReason == _iosIdleError,
      ),
    );
  }

  void _onIosQueue(Object? arguments) {
    if (arguments is! List) {
      _queue.add(const []);
      return;
    }

    final entries = <CastQueueEntry>[];
    for (final item in arguments) {
      if (item is! Map) continue;
      final itemId = (item['itemId'] as num?)?.toInt();
      final media = item['mediaInformation'];
      final contentId = media is Map ? media['contentID'] as String? : null;
      final contentUrl = media is Map ? media['contentURL'] as String? : null;
      if (itemId == null || (contentId == null && contentUrl == null)) continue;
      entries.add(
        CastQueueEntry(
          itemId: itemId,
          contentId: contentId,
          contentUrl: contentUrl,
        ),
      );
    }
    _queue.add(entries);
  }

  void _onIosPosition(Object? arguments) {
    if (arguments is! num) return;
    _positions.add(Duration(milliseconds: arguments.toInt()));
  }

  Map<String, dynamic>? _decode(String source) {
    try {
      final decoded = jsonDecode(source);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }
}
