import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/storages/generated_playlist_database.dart';

class CurrentDayNotifier extends Notifier<String> {
  @override
  String build() => generatedPlaylistDayKey(DateTime.now());

  void check() {
    final today = generatedPlaylistDayKey(DateTime.now());
    if (today != state) state = today;
  }
}

final currentDayProvider = NotifierProvider<CurrentDayNotifier, String>(
  CurrentDayNotifier.new,
);
