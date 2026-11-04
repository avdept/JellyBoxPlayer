import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/storages/pins_database.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

final pinsDatabaseProvider = Provider<PinsDatabase>(
  (ref) => PinsDatabase(
    ref.watch(downloadDatabaseProvider),
    userId: ref.watch(currentUserProvider.select((user) => user?.userId)),
  ),
);
