import 'package:jplayer/src/data/backend/server_session.dart';

class QuickConnectRequest {
  const QuickConnectRequest({required this.code, required this.secret});

  final String code;
  final String secret;
}

abstract class QuickConnectAuthenticator {
  const QuickConnectAuthenticator();

  Future<QuickConnectRequest> initiate({required String serverUrl});

  Future<ServerSession?> poll(
    QuickConnectRequest request, {
    required String serverUrl,
  });
}
