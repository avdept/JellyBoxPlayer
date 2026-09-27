import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/storages/instant_mix_database.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

final instantMixDatabaseProvider = Provider<InstantMixDatabase>(
  (ref) => InstantMixDatabase(
    ref.watch(downloadDatabaseProvider),
    userId: ref.watch(currentUserProvider.select((user) => user?.userId)),
  ),
);
