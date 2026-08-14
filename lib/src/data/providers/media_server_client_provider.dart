import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/backend/jellyfin/jellyfin_client.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/current_server_type_provider.dart';

final mediaServerClientProvider = Provider<MediaServerClient>((ref) {
  final user = ref.watch(currentUserProvider);
  final baseUrl = ref.watch(baseUrlProvider) ?? '';
  final serverType = ref.watch(currentServerTypeProvider) ?? ServerType.jellyfin;
  switch (serverType) {
    case ServerType.jellyfin:
      return JellyfinClient(
        dio: ref.watch(dioProvider),
        baseUrl: baseUrl,
        userId: user?.userId ?? '',
        token: user?.token ?? '',
        deviceId: deviceId,
      );
  }
});
