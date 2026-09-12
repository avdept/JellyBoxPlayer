import 'package:dio/dio.dart';
import 'package:jplayer/src/data/backend/emby/emby_auth_headers.dart';
import 'package:jplayer/src/data/backend/emby/emby_authenticator.dart';
import 'package:jplayer/src/data/backend/emby/emby_client.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_auth_headers.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_authenticator.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_client.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_quick_connect.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/mediabrowser_probe.dart';
import 'package:jplayer/src/data/backend/quick_connect.dart';
import 'package:jplayer/src/data/backend/server_auth_headers.dart';
import 'package:jplayer/src/data/backend/server_probe.dart';
import 'package:jplayer/src/data/backend/server_session.dart';
import 'package:jplayer/src/data/backend/server_type.dart';

List<ServerProbe> defaultServerProbes(Dio client) => [
  MediaBrowserProbe(client),
];

MediaServerAuthenticator authenticatorFor(
  ServerType serverType, {
  required Dio dio,
}) => switch (serverType) {
  ServerType.jellyfin => JellyfinAuthenticator(dio),
  ServerType.emby => EmbyAuthenticator(dio),
};

QuickConnectAuthenticator? quickConnectFor(
  ServerType serverType, {
  required Dio dio,
}) => switch (serverType) {
  ServerType.jellyfin => JellyfinQuickConnect(dio),
  ServerType.emby => null,
};

ServerAuthHeaders authHeadersFor(
  ServerType serverType, {
  required String deviceId,
  required String deviceName,
  required String version,
}) => switch (serverType) {
  ServerType.jellyfin => JellyfinAuthHeaders(
    deviceId: deviceId,
    deviceName: deviceName,
    version: version,
  ),
  ServerType.emby => EmbyAuthHeaders(
    deviceId: deviceId,
    deviceName: deviceName,
    version: version,
  ),
};

MediaServerClient clientFor(
  ServerType serverType, {
  required Dio dio,
  required String baseUrl,
  required String userId,
  required String token,
  required String deviceId,
}) => switch (serverType) {
  ServerType.jellyfin => JellyfinClient(
    dio: dio,
    baseUrl: baseUrl,
    userId: userId,
    token: token,
    deviceId: deviceId,
  ),
  ServerType.emby => EmbyClient(
    dio: dio,
    baseUrl: baseUrl,
    userId: userId,
    token: token,
    deviceId: deviceId,
  ),
};
