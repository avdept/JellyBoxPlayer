import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';

final resolvedCapabilitiesProvider = FutureProvider<MediaServerCapabilities>(
  (ref) => ref.watch(mediaServerClientProvider).resolveCapabilities(),
);

final serverCapabilitiesProvider = Provider<MediaServerCapabilities>(
  (ref) =>
      ref.watch(resolvedCapabilitiesProvider).valueOrNull ??
      ref.watch(mediaServerClientProvider).capabilities,
);

final ratingsEnabledProvider = Provider<bool>(
  (ref) =>
      ref.watch(serverCapabilitiesProvider.select((c) => c.ratings)) &&
      !ref.watch(settingProvider(AppSetting.ratingsHidden)),
);
