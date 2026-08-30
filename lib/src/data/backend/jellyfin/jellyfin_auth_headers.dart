import 'package:jplayer/src/data/backend/server_auth_headers.dart';

class JellyfinAuthHeaders extends ServerAuthHeaders {
  const JellyfinAuthHeaders({
    required super.deviceId,
    required super.deviceName,
    required super.version,
  });

  static const authorizationHeader = 'authorization';

  @override
  Set<String> get managedKeys => const {authorizationHeader};

  @override
  Map<String, String> build({String? token}) => {
    authorizationHeader: mediaBrowserCredentials(
      deviceId: deviceId,
      deviceName: deviceName,
      version: version,
      token: token,
    ),
  };
}
