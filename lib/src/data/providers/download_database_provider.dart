import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';

final downloadDatabaseProvider = Provider<DownloadDatabase>(
  (ref) => DownloadDatabase(serverId: ref.watch(currentServerIdProvider) ?? ''),
);
