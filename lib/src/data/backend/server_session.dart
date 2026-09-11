import 'package:jplayer/src/data/params/params.dart';

class ServerSession {
  const ServerSession({
    required this.userId,
    required this.token,
    required this.serverId,
    this.serverName,
  });

  final String userId;
  final String token;
  final String serverId;
  final String? serverName;
}

// ignore: one_member_abstracts
abstract class MediaServerAuthenticator {
  const MediaServerAuthenticator();

  Future<ServerSession> signIn(
    UserCredentials credentials, {
    required String serverUrl,
  });
}
