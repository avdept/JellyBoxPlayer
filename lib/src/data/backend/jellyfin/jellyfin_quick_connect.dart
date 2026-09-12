import 'package:dio/dio.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/backend/mediabrowser_authenticator.dart';
import 'package:jplayer/src/data/backend/quick_connect.dart';
import 'package:jplayer/src/data/backend/server_session.dart';
import 'package:jplayer/src/data/params/params.dart';

class JellyfinQuickConnect extends QuickConnectAuthenticator {
  const JellyfinQuickConnect(this._client);

  final Dio _client;

  @override
  Future<QuickConnectRequest> initiate({required String serverUrl}) async {
    final response = await _api(serverUrl).initiateQuickConnect();
    final state = response.data;
    return QuickConnectRequest(code: state.code, secret: state.secret);
  }

  @override
  Future<ServerSession?> poll(
    QuickConnectRequest request, {
    required String serverUrl,
  }) async {
    final api = _api(serverUrl);
    final state = await api.quickConnectState(secret: request.secret);
    if (!state.data.authenticated) return null;

    final result = await api.signInWithQuickConnect(
      secret: QuickConnectSecret(secret: request.secret),
    );
    return mediaBrowserSession(result.data, serverUrl: serverUrl);
  }

  JellyfinApi _api(String serverUrl) =>
      JellyfinApi(_client, baseUrl: serverUrl);
}
