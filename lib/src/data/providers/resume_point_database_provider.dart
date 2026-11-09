import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/storages/resume_point_database.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

final resumePointDatabaseProvider = Provider<ResumePointDatabase>(
  (ref) => ResumePointDatabase(
    ref.watch(downloadDatabaseProvider),
    userId: ref.watch(currentUserProvider.select((user) => user?.userId)),
  ),
);
