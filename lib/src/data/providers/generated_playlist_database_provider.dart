import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/storages/generated_playlist_database.dart';

final generatedPlaylistDatabaseProvider = Provider<GeneratedPlaylistDatabase>(
  (ref) => GeneratedPlaylistDatabase(ref.watch(downloadDatabaseProvider)),
);
