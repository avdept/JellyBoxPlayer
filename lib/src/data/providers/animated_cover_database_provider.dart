import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/animated_artwork/animated_artwork_client.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/storages/animated_cover_database.dart';

final animatedCoverDatabaseProvider = Provider<AnimatedCoverDatabase>(
  (ref) => AnimatedCoverDatabase(ref.watch(downloadDatabaseProvider)),
);

final animatedArtworkClientProvider = Provider<AnimatedArtworkClient>(
  (ref) => AnimatedArtworkClient(),
);
