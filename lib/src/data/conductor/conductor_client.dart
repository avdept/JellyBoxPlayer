import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/data/conductor/conductor_models.dart';
import 'package:jplayer/src/data/conductor/phoenix_socket.dart';

class ConductorClient {
  ConductorClient({
    required this.endpoint,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  final Uri endpoint;

  final String userId;

  final String deviceId;
  final String deviceName;
  final String platform;

  PhoenixSocket? _socket;
  PhoenixChannel? _channel;
  StreamSubscription<PhoenixSocketState>? _socketState;

  final _devices = <String, ConductorDevice>{};

  var _doc = const SessionDoc();
  var _revision = 0;
  var _positionAgeMs = 0;
  String? _rendererId;

  final _docController = StreamController<SessionDoc>.broadcast();
  final _devicesController =
      StreamController<List<ConductorDevice>>.broadcast();
  final _statusController = StreamController<ConductorStatus>.broadcast();
  final _handoffController = StreamController<HandoffRequest>.broadcast();
  final _rendererController = StreamController<String?>.broadcast();

  Stream<SessionDoc> get docStream => _docController.stream;
  Stream<List<ConductorDevice>> get devicesStream => _devicesController.stream;
  Stream<ConductorStatus> get statusStream => _statusController.stream;

  Stream<HandoffRequest> get handoffStream => _handoffController.stream;

  Stream<String?> get rendererStream => _rendererController.stream;

  SessionDoc get doc => _doc;
  int get revision => _revision;

  int get positionAgeMs => _positionAgeMs;
  String? get rendererId => _rendererId;
  bool get isRenderer => _rendererId == deviceId;

  List<ConductorDevice> get devices {
    final list = _devices.values
        .map(
          (d) => d.copyWith(
            isRenderer: d.id == _rendererId,
            isSelf: d.id == deviceId,
          ),
        )
        .toList();
    list.sort((a, b) {
      if (a.isSelf != b.isSelf) return a.isSelf ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  String get _topic => 'session:$userId';

  Future<void> connect() async {
    if (_socket != null) return;

    _statusController.add(ConductorStatus.connecting);

    final socket = _socket = PhoenixSocket(
      endpoint: endpoint,
      params: {
        'user_id': userId,
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform,
      },
    );

    _socketState = socket.stateStream.listen((state) {
      switch (state) {
        case PhoenixSocketState.connecting:
          _statusController.add(ConductorStatus.connecting);
        case PhoenixSocketState.reconnecting:
          _statusController.add(ConductorStatus.reconnecting);
        case PhoenixSocketState.disconnected:
          _statusController.add(ConductorStatus.off);
        case PhoenixSocketState.connected:
          _emitStatus();
      }
    });

    final channel = _channel = socket.channel(_topic)
      ..on('session:state', _onSessionState)
      ..on('presence_state', _onPresenceState)
      ..on('presence_diff', _onPresenceDiff)
      ..on('handoff:begin', _onHandoffBegin);

    await socket.connect();
    if (!socket.isConnected) {
      _statusController.add(ConductorStatus.error);
      return;
    }

    try {
      await channel.join();
      _emitStatus();
    } on Object catch (error) {
      debugPrint('[conductor] join failed: $error');
      _statusController.add(ConductorStatus.error);
    }
  }

  Future<void> disconnect() async {
    await _socketState?.cancel();
    _socketState = null;
    await _channel?.leave();
    await _socket?.dispose();
    _socket = null;
    _channel = null;
    _devices.clear();
    _devicesController.add(const []);
    _statusController.add(ConductorStatus.off);
  }

  Future<void> publish(SessionDoc doc) async {
    final channel = _channel;
    if (channel == null || !channel.isJoined) return;

    try {
      final reply = await channel.push('state:update', {
        'doc': doc.toJson(),
        'revision': _revision,
      });
      _revision = (reply['revision'] as num?)?.toInt() ?? _revision;
      _doc = doc;
    } on Object catch (error) {
      debugPrint('[conductor] publish failed: $error');
    }
  }

  Future<void> handoffTo(String targetDeviceId) async {
    final channel = _channel;
    if (channel == null) throw StateError('conductor not connected');
    await channel.push('handoff', {'to': targetDeviceId});
  }

  Future<void> claimHere() async {
    final channel = _channel;
    if (channel == null) throw StateError('conductor not connected');
    await channel.push('renderer:claim', const {});
  }

  Future<void> announceRenderer() async {
    try {
      await _channel?.push('renderer:announce', const {});
    } on Object catch (error) {
      debugPrint('[conductor] renderer:announce failed: $error');
    }
  }

  Future<void> reportHandoffDone({
    required int audibleMs,
    Map<String, int> phases = const {},
  }) async {
    try {
      await _channel?.push('handoff:done', {
        'audible_ms': audibleMs,
        'phases': phases,
      });
    } on Object catch (error) {
      debugPrint('[conductor] handoff:done failed: $error');
    }
  }

  Future<void> reportSeekCorrected({
    required int targetMs,
    required int bufferedMs,
  }) async {
    try {
      await _channel?.push('seek:corrected', {
        'target_ms': targetMs,
        'buffered_ms': bufferedMs,
      });
    } on Object catch (error) {
      debugPrint('[conductor] seek:corrected failed: $error');
    }
  }

  Future<void> reportHandoffFailed(String reason) async {
    try {
      await _channel?.push('handoff:failed', {'reason': reason});
    } on Object catch (error) {
      debugPrint('[conductor] handoff:failed failed: $error');
    }
  }

  void _onSessionState(Map<String, dynamic> payload) {
    _revision = (payload['revision'] as num?)?.toInt() ?? _revision;
    _positionAgeMs = (payload['position_age_ms'] as num?)?.toInt() ?? 0;

    final previousRenderer = _rendererId;
    _rendererId = payload['renderer_id'] as String?;
    if (previousRenderer != _rendererId) {
      _rendererController.add(_rendererId);
    }

    final doc = payload['doc'];
    if (doc is Map) {
      _doc = SessionDoc.fromJson(doc.cast<String, dynamic>());
      _docController.add(_doc);
    }
    _devicesController.add(devices);
    _emitStatus();
  }

  void _onPresenceState(Map<String, dynamic> payload) {
    _devices.clear();
    payload.forEach((id, entry) {
      final device = ConductorDevice.fromPresence(id, entry);
      if (device != null) _devices[id] = device;
    });
    _devicesController.add(devices);
  }

  void _onPresenceDiff(Map<String, dynamic> payload) {
    ((payload['leaves'] as Map?) ?? const {}).forEach((id, _) {
      _devices.remove(id);
    });
    ((payload['joins'] as Map?) ?? const {}).forEach((id, entry) {
      final device = ConductorDevice.fromPresence(id as String, entry);
      if (device != null) _devices[id] = device;
    });
    _devicesController.add(devices);
  }

  void _onHandoffBegin(Map<String, dynamic> payload) {
    _revision = (payload['revision'] as num?)?.toInt() ?? _revision;
    _rendererId = payload['renderer_id'] as String?;

    final rawDoc = payload['doc'];
    final doc = rawDoc is Map
        ? SessionDoc.fromJson(rawDoc.cast<String, dynamic>())
        : _doc;
    _doc = doc;

    _devicesController.add(devices);
    _emitStatus();

    _handoffController.add(
      HandoffRequest(
        doc: doc,
        positionAgeMs: (payload['position_age_ms'] as num?)?.toInt() ?? 0,
        targetDeviceId: payload['to'] as String? ?? '',
        fromDeviceId: payload['from'] as String? ?? '',
        isForUs: payload['to'] == deviceId,
        receivedAt: DateTime.now(),
      ),
    );
  }

  void _emitStatus() {
    _statusController.add(
      isRenderer ? ConductorStatus.rendering : ConductorStatus.listening,
    );
  }

  Future<void> dispose() async {
    await disconnect();
    await _rendererController.close();
    await _docController.close();
    await _devicesController.close();
    await _statusController.close();
    await _handoffController.close();
  }
}

@immutable
class HandoffRequest {
  const HandoffRequest({
    required this.doc,
    required this.positionAgeMs,
    required this.targetDeviceId,
    required this.fromDeviceId,
    required this.isForUs,
    required this.receivedAt,
  });

  final SessionDoc doc;

  final int positionAgeMs;
  final String targetDeviceId;
  final String fromDeviceId;

  final bool isForUs;

  final DateTime receivedAt;

  Duration positionAt(
    DateTime now, {
    Duration startupAllowance = Duration.zero,
  }) {
    final reported = Duration(milliseconds: doc.trackPositionMs);

    if (!doc.playing) return reported;

    final elapsed =
        Duration(milliseconds: positionAgeMs) +
        now.difference(receivedAt) +
        startupAllowance;

    final target = reported + elapsed;
    return target.isNegative ? Duration.zero : target;
  }
}
