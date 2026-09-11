import 'package:jplayer/src/data/backend/server_session.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/params/params.dart';

abstract class MediaBrowserAuthenticator extends MediaServerAuthenticator {
  const MediaBrowserAuthenticator();

  Future<SignInResultDTO> authenticate(
    UserCredentials credentials, {
    required String serverUrl,
  });

  @override
  Future<ServerSession> signIn(
    UserCredentials credentials, {
    required String serverUrl,
  }) async {
    final result = await authenticate(credentials, serverUrl: serverUrl);
    return ServerSession(
      userId: result.user.id,
      token: result.accessToken,
      serverId: result.serverId.isNotEmpty ? result.serverId : serverUrl,
      serverName: result.user.name,
    );
  }
}
