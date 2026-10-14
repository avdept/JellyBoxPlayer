import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/downloads_revision_provider.dart';

final standaloneDownloadedSongsProvider = FutureProvider<List<DownloadedSong>>((
  ref,
) {
  ref.watch(downloadsRevisionProvider);
  return ref.watch(downloadDatabaseProvider).getStandaloneSongs();
});
