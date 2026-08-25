import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class PhoenixSocket {
  PhoenixSocket({
    required this.endpoint,
    required this.params,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.reconnectDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
    ],
  });

  final Uri endpoint;

  final Map<String, String> params;

  final Duration heartbeatInterval;
  final List<Duration> reconnectDelays;

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _messages;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  var _ref = 0;
  var _reconnectAttempt = 0;
  var _closedByUs = false;

  final _channels = <String, PhoenixChannel>{};
  final _pendingReplies = <String, Completer<Map<String, dynamic>>>{};
  final _stateController = StreamController<PhoenixSocketState>.broadcast();

  Stream<PhoenixSocketState> get stateStream => _stateController.stream;
  PhoenixSocketState _state = PhoenixSocketState.disconnected;
  PhoenixSocketState get state => _state;

  bool get isConnected => _state == PhoenixSocketState.connected;

  Uri get _socketUri {
    final base = endpoint.replace(
      scheme: endpoint.scheme == 'https' ? 'wss' : 'ws',
      pathSegments: [
        ...endpoint.pathSegments.where((s) => s.isNotEmpty),
        'socket',
        'websocket',
      ],
    );
    return base.replace(queryParameters: {...params, 'vsn': '2.0.0'});
  }

  Future<void> connect() async {
    _closedByUs = false;
    if (_ws != null) return;

    _setState(PhoenixSocketState.connecting);
    try {
      final ws = _ws = WebSocketChannel.connect(_socketUri);
      await ws.ready;
    } on Object catch (error) {
      debugPrint('[conductor] connect failed: $error');
      _ws = null;
      _scheduleReconnect();
      return;
    }

    _messages = _ws!.stream.listen(
      _onMessage,
      onDone: _onDisconnected,
      onError: (Object error) {
        debugPrint('[conductor] socket error: $error');
        _onDisconnected();
      },
    );

    _reconnectAttempt = 0;
    _setState(PhoenixSocketState.connected);
    _startHeartbeat();

    for (final channel in _channels.values) {
      unawaited(channel._rejoin());
    }
  }

  Future<void> disconnect() async {
    _closedByUs = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _messages?.cancel();
    await _ws?.sink.close();
    _ws = null;
    _messages = null;
    _setState(PhoenixSocketState.disconnected);
  }

  PhoenixChannel channel(String topic) =>
      _channels.putIfAbsent(topic, () => PhoenixChannel._(this, topic));

  String _nextRef() => (++_ref).toString();

  Future<Map<String, dynamic>> _push({
    required String topic,
    required String event,
    required Map<String, dynamic> payload,
    String? joinRef,
    Duration timeout = const Duration(seconds: 10),
  }) {
    final socket = _ws;
    if (socket == null) {
      return Future.error(StateError('conductor socket is not connected'));
    }

    final ref = _nextRef();
    final completer = Completer<Map<String, dynamic>>();
    _pendingReplies[ref] = completer;

    socket.sink.add(jsonEncode([joinRef, ref, topic, event, payload]));

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pendingReplies.remove(ref);
        throw TimeoutException('conductor did not reply to $event', timeout);
      },
    );
  }

  void _onMessage(dynamic raw) {
    final decoded = jsonDecode(raw as String);
    if (decoded is! List || decoded.length < 5) return;

    final ref = decoded[1] as String?;
    final topic = decoded[2] as String;
    final event = decoded[3] as String;
    final payload = (decoded[4] as Map?)?.cast<String, dynamic>() ?? {};

    if (event == 'phx_reply') {
      final completer = _pendingReplies.remove(ref);
      if (completer == null || completer.isCompleted) return;
      final status = payload['status'] as String?;
      final response =
          (payload['response'] as Map?)?.cast<String, dynamic>() ?? {};
      if (status == 'ok') {
        completer.complete(response);
      } else {
        completer.completeError(
          PhoenixError(event: 'phx_reply', payload: response),
        );
      }
      return;
    }

    _channels[topic]?._dispatch(event, payload);
  }

  void _onDisconnected() {
    _heartbeatTimer?.cancel();
    _ws = null;
    _messages = null;

    for (final completer in _pendingReplies.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('conductor socket closed'));
      }
    }
    _pendingReplies.clear();

    for (final channel in _channels.values) {
      channel._joined = false;
    }

    if (_closedByUs) {
      _setState(PhoenixSocketState.disconnected);
    } else {
      _setState(PhoenixSocketState.reconnecting);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_closedByUs) return;
    _reconnectTimer?.cancel();
    final delay =
        reconnectDelays[_reconnectAttempt.clamp(0, reconnectDelays.length - 1)];
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, () => unawaited(connect()));
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) async {
      try {
        await _push(
          topic: 'phoenix',
          event: 'heartbeat',
          payload: const {},
          timeout: const Duration(seconds: 5),
        );
      } on Object {
        debugPrint('[conductor] heartbeat failed, reconnecting');
        _onDisconnected();
      }
    });
  }

  void _setState(PhoenixSocketState next) {
    if (_state == next) return;
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
  }
}

enum PhoenixSocketState { disconnected, connecting, connected, reconnecting }

class PhoenixError implements Exception {
  PhoenixError({required this.event, required this.payload});

  final String event;
  final Map<String, dynamic> payload;

  String? get reason => payload['reason'] as String?;

  @override
  String toString() => 'PhoenixError($event): ${reason ?? payload}';
}

class PhoenixChannel {
  PhoenixChannel._(this._socket, this.topic);

  final PhoenixSocket _socket;
  final String topic;

  final _listeners = <String, List<void Function(Map<String, dynamic>)>>{};
  String? _joinRef;
  var _joined = false;

  bool get isJoined => _joined;

  VoidCallback on(String event, void Function(Map<String, dynamic>) handler) {
    _listeners.putIfAbsent(event, () => []).add(handler);
    return () => _listeners[event]?.remove(handler);
  }

  Future<Map<String, dynamic>> join([
    Map<String, dynamic> payload = const {},
  ]) async {
    final ref = _joinRef = _socket._nextRef();
    final reply = await _socket._push(
      topic: topic,
      event: 'phx_join',
      payload: payload,
      joinRef: ref,
    );
    _joined = true;
    return reply;
  }

  Future<Map<String, dynamic>> push(
    String event,
    Map<String, dynamic> payload,
  ) {
    if (!_joined) {
      return Future.error(StateError('channel $topic is not joined'));
    }
    return _socket._push(
      topic: topic,
      event: event,
      payload: payload,
      joinRef: _joinRef,
    );
  }

  Future<void> leave() async {
    if (!_joined) return;
    _joined = false;
    try {
      await _socket._push(
        topic: topic,
        event: 'phx_leave',
        payload: const {},
        joinRef: _joinRef,
      );
    } on Object {}
  }

  Future<void> _rejoin() async {
    try {
      await join();
    } on Object catch (error) {
      debugPrint('[conductor] rejoin $topic failed: $error');
    }
  }

  void _dispatch(String event, Map<String, dynamic> payload) {
    for (final handler in [...?_listeners[event]]) {
      handler(payload);
    }
  }
}
