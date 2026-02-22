import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/storages/playback_storage.dart';

final playbackStorageProvider = Provider<PlaybackStorage>(
  (_) => PlaybackStorage(),
);
