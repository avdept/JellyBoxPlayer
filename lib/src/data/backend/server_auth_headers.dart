import 'dart:io';

const clientName = 'JellyBox Player';

String getCurrentPlatformName() {
  if (Platform.isAndroid) {
    return 'Android';
  } else if (Platform.isIOS) {
    return 'iOS';
  } else if (Platform.isWindows) {
    return 'Windows';
  } else if (Platform.isMacOS) {
    return 'macOS';
  } else if (Platform.isLinux) {
    return 'Linux';
  } else {
    return 'Unknown';
  }
}

String mediaBrowserCredentials({
  required String deviceId,
  required String deviceName,
  required String version,
  String? token,
}) {
  final fields = <String>[
    if (token != null && token.isNotEmpty) 'Token="$token"',
    'Client="$clientName"',
    'Device="$deviceName"',
    'DeviceId="$deviceId"',
    'Version="$version"',
  ];
  return 'MediaBrowser ${fields.join(', ')}';
}

abstract class ServerAuthHeaders {
  const ServerAuthHeaders({
    required this.deviceId,
    required this.deviceName,
    required this.version,
  });

  final String deviceId;
  final String deviceName;
  final String version;

  Set<String> get managedKeys;

  Map<String, String> build({String? token});
}
