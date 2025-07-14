import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/storages/download_database.dart';

final downloadDatabaseProvider = Provider<DownloadDatabase>(
  (ref) => DownloadDatabase.instance,
);
