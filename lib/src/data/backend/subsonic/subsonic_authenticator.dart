import 'package:dio/dio.dart';
import 'package:jplayer/src/data/api/subsonic/subsonic_api.dart';
import 'package:jplayer/src/data/backend/server_session.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_credentials.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_envelope_interceptor.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_probe.dart';
import 'package:jplayer/src/data/params/params.dart';

class SubsonicAuthenticator extends MediaServerAuthenticator {
  SubsonicAuthenticator(this._client) {
    SubsonicEnvelopeInterceptor.install(_client);
  }

  final Dio _client;

  @override
  Future<ServerSession> signIn(
    UserCredentials credentials, {
    required String serverUrl,
  }) async {
    final subsonic = SubsonicCredentials.fromPassword(
      username: credentials.username,
      password: credentials.pw,
    );
    final envelope = await SubsonicApi(
      _client,
      baseUrl: serverUrl,
      credentials: subsonic,
    ).ping();
    return ServerSession(
      userId: credentials.username,
      token: subsonic.encodedToken,
      serverId: subsonicServerId(serverUrl),
      serverName: subsonicProductLabel(envelope.type),
    );
  }
}
