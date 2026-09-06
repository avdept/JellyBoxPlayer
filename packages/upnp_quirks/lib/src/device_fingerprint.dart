class DeviceFingerprint {
  const DeviceFingerprint({
    this.manufacturer,
    this.modelName,
    this.modelNumber,
    this.deviceType,
    this.friendlyName,
    this.actions = const {},
    this.sinkMimeTypes = const {},
    this.services = const {},
  });

  final String? manufacturer;
  final String? modelName;
  final String? modelNumber;
  final String? deviceType;
  final String? friendlyName;
  final Set<String> actions;
  final Set<String> sinkMimeTypes;
  final Set<String> services;

  String get searchable => [
    manufacturer,
    modelName,
    modelNumber,
    friendlyName,
    deviceType,
  ].whereType<String>().join(' ').toLowerCase();

  DeviceFingerprint redacted() => DeviceFingerprint(
    manufacturer: manufacturer,
    modelName: modelName,
    modelNumber: modelNumber,
    deviceType: deviceType,
    actions: actions,
    sinkMimeTypes: sinkMimeTypes,
    services: services,
  );

  Map<String, Object?> toJson() => {
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (modelName != null) 'modelName': modelName,
    if (modelNumber != null) 'modelNumber': modelNumber,
    if (deviceType != null) 'deviceType': deviceType,
    if (friendlyName != null) 'friendlyName': friendlyName,
    'actions': actions.toList()..sort(),
    'sinkMimeTypes': sinkMimeTypes.toList()..sort(),
    'services': services.toList()..sort(),
  };
}
