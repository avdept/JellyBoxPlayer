import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:jplayer/src/core/enums/enums.dart';

class CastReceiverStatus {
  const CastReceiverStatus({
    required this.status,
    this.itemId,
    this.contentId,
    this.duration,
    this.finished = false,
    this.failed = false,
  });

  final PlaybackStatus status;
  final int? itemId;
  final String? contentId;
  final Duration? duration;
  final bool finished;
  final bool failed;
}

class CastQueueEntry {
  const CastQueueEntry({required this.itemId, required this.contentId});

  final int itemId;
  final String contentId;
}

abstract class CastMediaFeed {
  Stream<CastReceiverStatus> get statuses;

  Stream<List<CastQueueEntry>> get queue;

  Stream<Duration> get positions;
}

class CastChannelFeed implements CastMediaFeed {
  CastChannelFeed._() {
    claimChannel();
  }

  void claimChannel() => _channel.setMethodCallHandler(_onCall);

  static final CastChannelFeed instance = CastChannelFeed._();

  static const _channel = MethodChannel(
    'com.felnanuke.google_cast.remote_media_client',
  );

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
          _ => PlaybackStatus.stopped,
        },
        itemId: (decoded['currentItemId'] as num?)?.toInt(),
        contentId: media is Map ? media['contentId'] as String? : null,
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
      if (itemId == null || contentId == null) continue;
      entries.add(CastQueueEntry(itemId: itemId, contentId: contentId));
    }
    _queue.add(entries);
  }

  void _onPosition(Object? arguments) {
    if (arguments is! Map) return;
    final progress = arguments['progress'];
    if (progress is! num) return;
    _positions.add(Duration(milliseconds: progress.toInt()));
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
