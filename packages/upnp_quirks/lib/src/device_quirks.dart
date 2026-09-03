enum SeekUnit {
  relativeTime('REL_TIME'),
  absoluteTime('ABS_TIME');

  const SeekUnit(this.wireName);

  final String wireName;
}

class DeviceQuirks {
  const DeviceQuirks({
    this.queueNextTrack = true,
    this.sendTrackMetadata = true,
    this.stopBeforeSetUri = false,
    this.seekUnit = SeekUnit.relativeTime,
    this.volumeRange = 100,
    this.pollInterval = const Duration(seconds: 1),
    this.idlePollsBeforeAdvance = 2,
    this.unsupportedMimeTypes = const {},
    this.note,
  });

  final bool queueNextTrack;
  final bool sendTrackMetadata;
  final bool stopBeforeSetUri;
  final SeekUnit seekUnit;
  final int volumeRange;
  final Duration pollInterval;
  final int idlePollsBeforeAdvance;
  final Set<String> unsupportedMimeTypes;
  final String? note;

  static const defaults = DeviceQuirks();

  DeviceQuirks copyWith({
    bool? queueNextTrack,
    bool? sendTrackMetadata,
    bool? stopBeforeSetUri,
    SeekUnit? seekUnit,
    int? volumeRange,
    Duration? pollInterval,
    int? idlePollsBeforeAdvance,
    Set<String>? unsupportedMimeTypes,
    String? note,
  }) => DeviceQuirks(
    queueNextTrack: queueNextTrack ?? this.queueNextTrack,
    sendTrackMetadata: sendTrackMetadata ?? this.sendTrackMetadata,
    stopBeforeSetUri: stopBeforeSetUri ?? this.stopBeforeSetUri,
    seekUnit: seekUnit ?? this.seekUnit,
    volumeRange: volumeRange ?? this.volumeRange,
    pollInterval: pollInterval ?? this.pollInterval,
    idlePollsBeforeAdvance:
        idlePollsBeforeAdvance ?? this.idlePollsBeforeAdvance,
    unsupportedMimeTypes: unsupportedMimeTypes ?? this.unsupportedMimeTypes,
    note: note ?? this.note,
  );

  Set<String> playableMimeTypes(Set<String> advertised) => {
    for (final mimeType in advertised)
      if (!unsupportedMimeTypes.contains(mimeType.toLowerCase())) mimeType,
  };

  double volumeToWire(double level) =>
      (level.clamp(0.0, 1.0) * volumeRange).roundToDouble();

  double volumeFromWire(num value) => (value / volumeRange).clamp(0.0, 1.0);

  Map<String, Object?> toJson() => {
    'queueNextTrack': queueNextTrack,
    'sendTrackMetadata': sendTrackMetadata,
    'stopBeforeSetUri': stopBeforeSetUri,
    'seekUnit': seekUnit.wireName,
    'volumeRange': volumeRange,
    'pollIntervalMs': pollInterval.inMilliseconds,
    'idlePollsBeforeAdvance': idlePollsBeforeAdvance,
    if (unsupportedMimeTypes.isNotEmpty)
      'unsupportedMimeTypes': unsupportedMimeTypes.toList()..sort(),
    if (note != null) 'note': note,
  };
}
