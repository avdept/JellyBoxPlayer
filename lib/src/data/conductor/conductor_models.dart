import 'package:flutter/foundation.dart';

@immutable
class SessionDoc {
  const SessionDoc({
    this.backendRef,
    this.albumId,
    this.itemIds = const [],
    this.queuePosition = 0,
    this.trackPositionMs = 0,
    this.playing = false,
    this.shuffle = false,
    this.repeat = 'off',
    this.updatedByDevice,
  });

  factory SessionDoc.fromJson(Map<String, dynamic> json) => SessionDoc(
    backendRef: json['backend_ref'] as String?,
    albumId: json['album_id'] as String?,
    itemIds: ((json['item_ids'] as List?) ?? const [])
        .map((id) => id as String)
        .toList(),
    queuePosition: (json['queue_position'] as num?)?.toInt() ?? 0,
    trackPositionMs: (json['track_position_ms'] as num?)?.toInt() ?? 0,
    playing: json['playing'] as bool? ?? false,
    shuffle: json['shuffle'] as bool? ?? false,
    repeat: json['repeat'] as String? ?? 'off',
    updatedByDevice: json['updated_by_device'] as String?,
  );

  final String? backendRef;
  final String? albumId;
  final List<String> itemIds;
  final int queuePosition;
  final int trackPositionMs;
  final bool playing;
  final bool shuffle;
  final String repeat;
  final String? updatedByDevice;

  bool get isEmpty => itemIds.isEmpty;

  String? get currentItemId =>
      queuePosition >= 0 && queuePosition < itemIds.length
      ? itemIds[queuePosition]
      : null;

  Map<String, dynamic> toJson() => {
    'backend_ref': backendRef,
    'album_id': albumId,
    'item_ids': itemIds,
    'queue_position': queuePosition,
    'track_position_ms': trackPositionMs,
    'playing': playing,
    'shuffle': shuffle,
    'repeat': repeat,
  };

  bool differsStructurallyFrom(SessionDoc other) =>
      backendRef != other.backendRef ||
      albumId != other.albumId ||
      queuePosition != other.queuePosition ||
      playing != other.playing ||
      shuffle != other.shuffle ||
      repeat != other.repeat ||
      !listEquals(itemIds, other.itemIds);

  SessionDoc copyWith({
    String? backendRef,
    String? albumId,
    List<String>? itemIds,
    int? queuePosition,
    int? trackPositionMs,
    bool? playing,
    bool? shuffle,
    String? repeat,
  }) => SessionDoc(
    backendRef: backendRef ?? this.backendRef,
    albumId: albumId ?? this.albumId,
    itemIds: itemIds ?? this.itemIds,
    queuePosition: queuePosition ?? this.queuePosition,
    trackPositionMs: trackPositionMs ?? this.trackPositionMs,
    playing: playing ?? this.playing,
    shuffle: shuffle ?? this.shuffle,
    repeat: repeat ?? this.repeat,
    updatedByDevice: updatedByDevice,
  );
}

@immutable
class ConductorDevice {
  const ConductorDevice({
    required this.id,
    required this.name,
    required this.platform,
    this.isRenderer = false,
    this.isSelf = false,
  });

  final String id;
  final String name;
  final String platform;

  final bool isRenderer;
  final bool isSelf;

  ConductorDevice copyWith({bool? isRenderer, bool? isSelf}) => ConductorDevice(
    id: id,
    name: name,
    platform: platform,
    isRenderer: isRenderer ?? this.isRenderer,
    isSelf: isSelf ?? this.isSelf,
  );

  static ConductorDevice? fromPresence(String id, Object? entry) {
    if (entry is! Map) return null;
    final metas = entry['metas'];
    if (metas is! List || metas.isEmpty) return null;
    final meta = metas.first;
    if (meta is! Map) return null;

    return ConductorDevice(
      id: id,
      name: meta['device_name'] as String? ?? id,
      platform: meta['platform'] as String? ?? 'unknown',
    );
  }
}

enum ConductorStatus {
  off,

  connecting,

  listening,

  rendering,

  reconnecting,

  error,
}
