import 'dart:async';
import 'dart:io' show pid;

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/discord/discord_activity.dart';
import 'package:jplayer/src/core/discord/discord_frame.dart';
import 'package:jplayer/src/core/discord/discord_transport.dart';

class DiscordPresenceClient {
  DiscordPresenceClient({
    required this.applicationId,
    Future<DiscordTransport?> Function() connect = openDiscordTransport,
    int sendBudget = _defaultSendBudget,
    Duration sendWindow = _defaultSendWindow,
    List<Duration> retryDelays = _defaultRetryDelays,
  }) : _connect = connect,
       _sendBudget = sendBudget,
       _sendWindow = sendWindow,
       _retryDelays = retryDelays;

  static const _defaultSendBudget = 4;
  static const _defaultSendWindow = Duration(seconds: 20);
  static const _fatalCloseCodes = {4000, 4002, 4005, 4006};

  static const _defaultRetryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 20),
    Duration(seconds: 60),
  ];

  final String applicationId;

  final Future<DiscordTransport?> Function() _connect;
  final int _sendBudget;
  final Duration _sendWindow;
  final List<Duration> _retryDelays;
  final _sendTimes = <DateTime>[];
  final _reader = DiscordFrameReader();

  DiscordTransport? _transport;
  StreamSubscription<List<int>>? _subscription;
  Timer? _retry;
  Timer? _throttle;
  DiscordActivity? _desired;
  DiscordActivity? _sent;
  var _attempt = 0;
  var _ready = false;
  var _started = false;
  var _nonce = 0;

  bool get isReady => _ready;

  void start() {
    if (_started) return;
    _started = true;
    unawaited(_open());
  }

  void setActivity(DiscordActivity? activity) {
    if (activity == _desired) return;
    _desired = activity;
    _flush();
  }

  Future<void> stop() async {
    _started = false;
    _retry?.cancel();
    _throttle?.cancel();
    _retry = null;
    _throttle = null;
    if (_ready && _desired != null) _sendActivity(null);
    _desired = null;
    _sendTimes.clear();
    _attempt = 0;
    await _teardown();
  }

  Future<void> _open() async {
    if (!_started || _transport != null) return;

    DiscordTransport? transport;
    try {
      transport = await _connect();
    } on Object catch (error) {
      debugPrint('[Discord] connect failed: $error');
    }
    if (transport == null) {
      debugPrint(
        '[Discord] no IPC socket found; is the desktop client running?',
      );
      _scheduleRetry();
      return;
    }
    if (!_started) {
      await transport.close();
      return;
    }

    _transport = transport;
    _reader.reset();
    _ready = false;
    _sent = null;
    _subscription = transport.incoming.listen(
      _onData,
      onError: (Object error) {
        debugPrint('[Discord] transport error: $error');
        _reconnect();
      },
      onDone: _reconnect,
      cancelOnError: true,
    );
    _send(DiscordOpcode.handshake, {'v': 1, 'client_id': applicationId});
  }

  void _onData(List<int> chunk) {
    final List<DiscordFrame> frames;
    try {
      frames = _reader.add(chunk);
    } on Object catch (error) {
      debugPrint('[Discord] malformed frame: $error');
      _reconnect();
      return;
    }

    for (final frame in frames) {
      switch (frame.opcode) {
        case DiscordOpcode.ping:
          _send(DiscordOpcode.pong, frame.payload);
        case DiscordOpcode.close:
          _onClose(frame.payload);
          return;
        case DiscordOpcode.frame:
          _onCommand(frame.payload);
      }
    }
  }

  void _onClose(Map<String, Object?> payload) {
    debugPrint('[Discord] connection closed: $payload');
    if (_fatalCloseCodes.contains(payload['code'])) {
      _started = false;
      unawaited(_teardown());
      return;
    }
    _reconnect();
  }

  void _onCommand(Map<String, Object?> payload) {
    switch (payload['evt']) {
      case 'READY':
        _ready = true;
        _attempt = 0;
        _sent = null;
        _flush();
      case 'ERROR':
        debugPrint('[Discord] rejected: ${payload['data']}');
    }
  }

  void _flush() {
    if (!_ready || _transport == null || _desired == _sent) return;

    final now = DateTime.now();
    _sendTimes.removeWhere((sent) => now.difference(sent) >= _sendWindow);
    if (_sendTimes.length >= _sendBudget) {
      final wait = _sendWindow - now.difference(_sendTimes.first);
      _throttle ??= Timer(wait, () {
        _throttle = null;
        _flush();
      });
      return;
    }

    _sendTimes.add(now);
    _sent = _desired;
    _sendActivity(_desired);
  }

  void _sendActivity(DiscordActivity? activity) => _send(DiscordOpcode.frame, {
    'cmd': 'SET_ACTIVITY',
    'nonce': '${++_nonce}',
    'args': {'pid': pid, 'activity': activity?.toJson()},
  });

  void _send(int opcode, Map<String, Object?> payload) {
    final transport = _transport;
    if (transport == null) return;
    try {
      transport.send(encodeDiscordFrame(opcode, payload));
    } on Object catch (error) {
      debugPrint('[Discord] send failed: $error');
      _reconnect();
    }
  }

  void _reconnect() => unawaited(_teardown().then((_) => _scheduleRetry()));

  Future<void> _teardown() async {
    final transport = _transport;
    _transport = null;
    _ready = false;
    _sent = null;

    try {
      await _subscription?.cancel();
      _subscription = null;
      await transport?.close();
    } on Object catch (error) {
      debugPrint('[Discord] teardown failed: $error');
    }
  }

  void _scheduleRetry() {
    if (!_started || _retry != null || _transport != null) return;
    final delay = _retryDelays[_attempt.clamp(0, _retryDelays.length - 1)];
    _attempt++;
    _retry = Timer(delay, () {
      _retry = null;
      unawaited(_open());
    });
  }
}
