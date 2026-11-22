import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/providers/play_history_database_provider.dart';
import 'package:jplayer/src/domain/play_history/played_song_hydrator.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

final playedSongHydratorProvider = Provider<PlayedSongHydrator>(
  (ref) => PlayedSongHydrator(
    ref.watch(playHistoryDatabaseProvider),
    ref.watch(mediaServerClientProvider),
    offline: () => ref.read(isOfflineProvider),
  ),
);
