import 'package:optional_features/src/upnp_quirks/device_queue.dart';

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
    this.knownMimeTypes = const {},
    this.seekTranscodes = true,
    this.transcodeAsRadio = false,
    this.urlNeedsExtension = false,
    this.maxSampleRate,
    this.maxBitDepth,
    this.maxChannels,
    this.queueOverride,
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
  final Set<String> knownMimeTypes;
  final bool seekTranscodes;
  final bool transcodeAsRadio;
  final bool urlNeedsExtension;
  final int? maxSampleRate;
  final int? maxBitDepth;
  final int? maxChannels;
  final DeviceQueueKind? queueOverride;
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
    Set<String>? knownMimeTypes,
    bool? seekTranscodes,
    bool? transcodeAsRadio,
    bool? urlNeedsExtension,
    int? maxSampleRate,
    int? maxBitDepth,
    int? maxChannels,
    DeviceQueueKind? queueOverride,
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
    knownMimeTypes: knownMimeTypes ?? this.knownMimeTypes,
    seekTranscodes: seekTranscodes ?? this.seekTranscodes,
    transcodeAsRadio: transcodeAsRadio ?? this.transcodeAsRadio,
    urlNeedsExtension: urlNeedsExtension ?? this.urlNeedsExtension,
    maxSampleRate: maxSampleRate ?? this.maxSampleRate,
    maxBitDepth: maxBitDepth ?? this.maxBitDepth,
    maxChannels: maxChannels ?? this.maxChannels,
    queueOverride: queueOverride ?? this.queueOverride,
    note: note ?? this.note,
  );

  Set<String> playableMimeTypes(Set<String> advertised) => {
    for (final mimeType in {...advertised, ...knownMimeTypes})
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
    'knownMimeTypes': knownMimeTypes.toList()..sort(),
    'seekTranscodes': seekTranscodes,
    'transcodeAsRadio': transcodeAsRadio,
    'urlNeedsExtension': urlNeedsExtension,
    if (maxSampleRate != null) 'maxSampleRate': maxSampleRate,
    if (maxBitDepth != null) 'maxBitDepth': maxBitDepth,
    if (maxChannels != null) 'maxChannels': maxChannels,
    'idlePollsBeforeAdvance': idlePollsBeforeAdvance,
    if (unsupportedMimeTypes.isNotEmpty)
      'unsupportedMimeTypes': unsupportedMimeTypes.toList()..sort(),
    if (queueOverride != null) 'queueOverride': queueOverride!.name,
    if (note != null) 'note': note,
  };
}
