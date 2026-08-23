import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

final sessionScopedProviders = <ProviderOrFamily>[
  mediaServerClientProvider,
  imageServiceProvider,
  currentLibraryProvider,
  audioQueueProvider,
  setPlaybackProvider,
  downloadManagerProvider,
  downloadedAlbumsProvider,
  currentDayProvider,
  filterProvider,
  carFilterProvider,
  lyricsVisibleProvider,
  studioModeVisibleProvider,
];
