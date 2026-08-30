import 'package:jplayer/src/data/backend/server_auth_headers.dart';

class EmbyAuthHeaders extends ServerAuthHeaders {
  const EmbyAuthHeaders({
    required super.deviceId,
    required super.deviceName,
    required super.version,
  });

  static const authorizationHeader = 'x-emby-authorization';
  static const tokenHeader = 'x-emby-token';

  @override
  Set<String> get managedKeys => const {authorizationHeader, tokenHeader};

  @override
  Map<String, String> build({String? token}) => {
    authorizationHeader: mediaBrowserCredentials(
      deviceId: deviceId,
      deviceName: deviceName,
      version: version,
    ),
    if (token != null && token.isNotEmpty) tokenHeader: token,
  };
}
