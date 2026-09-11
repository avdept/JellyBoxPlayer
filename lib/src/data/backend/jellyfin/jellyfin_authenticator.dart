import 'package:dio/dio.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/backend/mediabrowser_authenticator.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/params/params.dart';

class JellyfinAuthenticator extends MediaBrowserAuthenticator {
  const JellyfinAuthenticator(this._client);

  final Dio _client;

  @override
  Future<SignInResultDTO> authenticate(
    UserCredentials credentials, {
    required String serverUrl,
  }) async {
    final response = await JellyfinApi(
      _client,
      baseUrl: serverUrl,
    ).signIn(credentials: credentials);
    return response.data;
  }
}
