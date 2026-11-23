import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/generated_playlist_database_provider.dart';
import 'package:jplayer/src/data/providers/instant_mix_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/providers/pins_database_provider.dart';
import 'package:jplayer/src/data/providers/resume_point_database_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/sync/sync_hydrator.dart';

final syncHydratorProvider = Provider<SyncHydrator>(
  (ref) => SyncHydrator(
    client: ref.watch(mediaServerClientProvider),
    resumePoints: ref.watch(resumePointDatabaseProvider),
    pins: ref.watch(pinsDatabaseProvider),
    generated: ref.watch(generatedPlaylistDatabaseProvider),
    instantMixes: ref.watch(instantMixDatabaseProvider),
    userId: ref.watch(currentUserProvider.select((user) => user?.userId)),
  ),
);
