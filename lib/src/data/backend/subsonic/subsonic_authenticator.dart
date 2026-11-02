import 'package:dio/dio.dart';
import 'package:jplayer/src/data/api/subsonic/subsonic_api.dart';
import 'package:jplayer/src/data/backend/server_session.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_credentials.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_envelope_interceptor.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_probe.dart';
import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';
import 'package:jplayer/src/data/params/params.dart';

class SubsonicAuthenticator extends MediaServerAuthenticator {
  SubsonicAuthenticator(this._client) {
    SubsonicEnvelopeInterceptor.install(_client);
  }

  static const tokenAuthUnsupportedCode = 41;

  final Dio _client;

  @override
  Future<ServerSession> signIn(
    UserCredentials credentials, {
    required String serverUrl,
  }) async {
    try {
      return await _signInWith(
        SubsonicCredentials.fromPassword(
          username: credentials.username,
          password: credentials.pw,
        ),
        serverUrl: serverUrl,
      );
    } on DioException catch (error) {
      if (!rejectsTokenAuth(error)) rethrow;
    }
    return _signInWith(
      SubsonicCredentials.plain(
        username: credentials.username,
        password: credentials.pw,
      ),
      serverUrl: serverUrl,
    );
  }

  static bool rejectsTokenAuth(DioException error) {
    final envelope = SubsonicApi.envelopeOf(error.response?.data);
    if (envelope == null) return false;
    return SubsonicEnvelopeDTO.fromJson(envelope).error?.code ==
        tokenAuthUnsupportedCode;
  }

  Future<ServerSession> _signInWith(
    SubsonicCredentials subsonic, {
    required String serverUrl,
  }) async {
    final envelope = await SubsonicApi(
      _client,
      baseUrl: serverUrl,
      credentials: subsonic,
    ).ping();
    return ServerSession(
      userId: subsonic.username,
      token: subsonic.encodedToken,
      serverId: subsonicServerId(serverUrl),
      serverName: subsonicProductLabel(envelope.type),
    );
  }
}
