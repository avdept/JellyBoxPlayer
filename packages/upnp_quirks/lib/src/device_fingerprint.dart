class DeviceFingerprint {
  const DeviceFingerprint({
    this.manufacturer,
    this.modelName,
    this.modelNumber,
    this.deviceType,
    this.friendlyName,
    this.actions = const {},
    this.sinkMimeTypes = const {},
  });

  final String? manufacturer;
  final String? modelName;
  final String? modelNumber;
  final String? deviceType;
  final String? friendlyName;
  final Set<String> actions;
  final Set<String> sinkMimeTypes;

  String get searchable => [
    manufacturer,
    modelName,
    modelNumber,
    friendlyName,
    deviceType,
  ].whereType<String>().join(' ').toLowerCase();

  Map<String, Object?> toJson() => {
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (modelName != null) 'modelName': modelName,
    if (modelNumber != null) 'modelNumber': modelNumber,
    if (deviceType != null) 'deviceType': deviceType,
    if (friendlyName != null) 'friendlyName': friendlyName,
    'actions': actions.toList()..sort(),
    'sinkMimeTypes': sinkMimeTypes.toList()..sort(),
  };
}
